-- DATA2001 Project - Greater Sydney Analysis
-- Authors: Lakshya Sakhuja (540863213), Ayush Arora (540906543) and Drishti Nehra (530685294)

-- USYD CODE CITATION ACKNOWLEDGEMENT
-- This file contains acknowledgements of code.

-- This SQL script computes an extended accessibility score per SA2 based on weighted public transport stop density, normalised by area and scaled using z-scores and the sigmoid function.
-- Run this file step by step.


-- Step 1: Valid SA2s with population >= 100 in selected SA4s
-- Filters SA2s to only those within your 3 chosen SA4s (City + Eastern + Blacktown) and ensures population is not too low for statistical reliability.

SELECT sa2_code, sa2_name, areasqkm
FROM sa2_regions
WHERE sa4_name IN (
  'Sydney - City and Inner South',
  'Sydney - Eastern Suburbs',
  'Sydney - Blacktown'
)
AND sa2_code IN (
  SELECT sa2_code::text
  FROM population_data
  WHERE total_people >= 100
);


-- Step 2: Weighted stop count by type
-- Counts all public transport stops in each SA2 and applies weights: 2 points for major stops (e.g., interchanges or location_type = 1), and 1 point for others.

SELECT 
  r.sa2_code,
  r.sa2_name,
  r.areasqkm,
  COUNT(*) FILTER (
    WHERE LOWER(s.stop_name) LIKE '%interchange%' OR s.location_type = 1
  ) * 2 +
  COUNT(*) FILTER (
    WHERE NOT (LOWER(s.stop_name) LIKE '%interchange%' OR s.location_type = 1)
  ) AS weighted_stops
FROM stops_data s
JOIN sa2_regions r 
  ON ST_Contains(r.geometry, ST_SetSRID(ST_MakePoint(s.stop_lon, s.stop_lat), 4326))
JOIN population_data p 
  ON r.sa2_code = p.sa2_code::text
WHERE p.total_people >= 100
  AND r.sa4_name IN (
    'Sydney - City and Inner South',
    'Sydney - Eastern Suburbs',
    'Sydney - Blacktown'
  )
GROUP BY r.sa2_code, r.sa2_name, r.areasqkm;


-- Step 3: Compute stop density (per sqkm)
-- Calculates stop density as the number of weighted stops per square kilometre to account for spatial compactness of public transport.

WITH weighted_accessibility AS (
  SELECT 
    r.sa2_code,
    r.sa2_name,
    r.areasqkm,
    COUNT(*) FILTER (
      WHERE LOWER(s.stop_name) LIKE '%interchange%' OR s.location_type = 1
    ) * 2 +
    COUNT(*) FILTER (
      WHERE NOT (LOWER(s.stop_name) LIKE '%interchange%' OR s.location_type = 1)
    ) AS weighted_stops
  FROM stops_data s
  JOIN sa2_regions r 
    ON ST_Contains(r.geometry, ST_SetSRID(ST_MakePoint(s.stop_lon, s.stop_lat), 4326))
  JOIN population_data p 
    ON r.sa2_code = p.sa2_code::text
  WHERE p.total_people >= 100
    AND r.sa4_name IN (
      'Sydney - City and Inner South',
      'Sydney - Eastern Suburbs',
      'Sydney - Blacktown'
    )
  GROUP BY r.sa2_code, r.sa2_name, r.areasqkm
)

SELECT 
  sa2_code,
  sa2_name,
  areasqkm,
  weighted_stops,
  weighted_stops / NULLIF(areasqkm, 0) AS stop_density_score
FROM weighted_accessibility
ORDER BY stop_density_score DESC;


-- Step 4: Z-score normalisation and sigmoid scoring
-- Standardises the stop density values across SA2s using z-score, then applies a sigmoid function to convert them into a final 0–1 accessibility score.

CREATE TABLE pt_accessibility_scores AS
WITH density AS (
  SELECT 
    sa2_code,
    sa2_name,
    areasqkm,
    weighted_stops,
    weighted_stops / NULLIF(areasqkm, 0) AS stop_density_score
  FROM (
    SELECT 
      r.sa2_code,
      r.sa2_name,
      r.areasqkm,
      COUNT(*) FILTER (
        WHERE LOWER(s.stop_name) LIKE '%interchange%' OR s.location_type = 1
      ) * 2 +
      COUNT(*) FILTER (
        WHERE NOT (LOWER(s.stop_name) LIKE '%interchange%' OR s.location_type = 1)
      ) AS weighted_stops
    FROM stops_data s
    JOIN sa2_regions r 
      ON ST_Contains(r.geometry, ST_SetSRID(ST_MakePoint(s.stop_lon, s.stop_lat), 4326))
    JOIN population_data p 
      ON r.sa2_code = p.sa2_code::text
    WHERE p.total_people >= 100
      AND r.sa4_name IN (
        'Sydney - City and Inner South',
        'Sydney - Eastern Suburbs',
        'Sydney - Blacktown'
      )
    GROUP BY r.sa2_code, r.sa2_name, r.areasqkm
  ) sub
),

z_and_score AS (
  SELECT 
    sa2_code,
    sa2_name,
    stop_density_score,
    (stop_density_score - AVG(stop_density_score) OVER()) / NULLIF(STDDEV_POP(stop_density_score) OVER(), 0) AS z_score,
    1 / (1 + EXP(-(
      (stop_density_score - AVG(stop_density_score) OVER()) / NULLIF(STDDEV_POP(stop_density_score) OVER(), 0)
    ))) AS raw_score
  FROM density
)

SELECT 
  sa2_code,
  sa2_name,
  ROUND(stop_density_score::numeric, 2) AS stop_density_per_sqkm,
  ROUND(z_score::numeric, 3) AS z_score,
  ROUND(raw_score::numeric, 4) AS pt_accessibility_score
FROM z_and_score
ORDER BY pt_accessibility_score DESC;


-- Step 5: Indexing and creating keys.

-- Spatial index
CREATE INDEX selected_sa4_pois_geom_idx
ON selected_sa4_pois
USING GIST (geometry);

-- Attribute index
CREATE INDEX selected_sa4_pois_sa2_idx
ON selected_sa4_pois (sa2_name);

-- Primary Keys
ALTER TABLE pt_accessibility_scores
ADD CONSTRAINT pt_accessibility_scores_pkey PRIMARY KEY (sa2_code);

-- Foreign Keys

ALTER TABLE pt_accessibility_scores
ADD CONSTRAINT fk_pt_accessibility_sa2code
FOREIGN KEY (sa2_code) REFERENCES sa2_regions(sa2_code);

ALTER TABLE pt_accessibility_scores
ADD CONSTRAINT fk_pt_accessibility_sa2name
FOREIGN KEY (sa2_name) REFERENCES sa2_regions(sa2_name);




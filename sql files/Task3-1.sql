-- DATA2001 Project - Greater Sydney Analysis
-- Authors: Lakshya Sakhuja (540863213), Ayush Arora (540906543) and Drishti Nehra (530685294)

-- USYD CODE CITATION ACKNOWLEDGEMENT
-- This file contains acknowledgements of code.

-- This SQL script computes a well-resourced score per SA2 region by combining business, transport, education, and POI access.
-- Run this file step by step.


-- Step 1: Valid SA2s with population >= 100 in selected SA4s
-- Filters SA2s to only those within your 3 chosen SA4s (City + Eastern + Blacktown) and ensures population is not too low for statistical reliability.

SELECT sa2_code, sa2_name, total_people
FROM population_data
WHERE total_people >= 100
  AND sa2_code::text IN (
    SELECT sa2_code
    FROM sa2_regions
    WHERE sa4_name IN (
      'Sydney - City and Inner South',
      'Sydney - Eastern Suburbs',
      'Sydney - Blacktown'
    )
  );
  

-- Step 2: Business density
-- Calculates number of businesses per 1000 people for each SA2 to assess local economic activity.

SELECT 
  b.sa2_code,
  b.sa2_name,
  SUM(b.total_businesses)::float / p.total_people * 1000 AS businesses_per_1000
FROM business_data b
JOIN population_data p 
  ON b.sa2_code = p.sa2_code
JOIN sa2_regions r 
  ON b.sa2_code::text = r.sa2_code
WHERE p.total_people >= 100
  AND r.sa4_name IN (
    'Sydney - City and Inner South',
    'Sydney - Eastern Suburbs',
    'Sydney - Blacktown'
  )
GROUP BY b.sa2_code, b.sa2_name, p.total_people
ORDER BY businesses_per_1000 DESC;


-- Step 3: Public transport accessibility
-- Counts how many stops are located in each SA2 using a spatial match with point geometry.

SELECT 
  r.sa2_code,
  r.sa2_name,
  COUNT(*) AS num_stops
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
GROUP BY r.sa2_code, r.sa2_name
ORDER BY num_stops DESC;


-- Step 4: School catchment access
-- Measures education access as number of primary school catchments per 1000 residents aged 0–19.

SELECT 
  r.sa2_code,
  r.sa2_name,
  COUNT(*)::float / (
    pop."04_people" + pop."59_people" + pop."1014_people" + pop."1519_people"
  ) * 1000 AS schools_per_1000_young
FROM school_catchments_primary s
JOIN sa2_regions r 
  ON ST_Intersects(s.geometry, r.geometry)
JOIN population_data pop 
  ON r.sa2_code = pop.sa2_code::text
WHERE (pop."04_people" + pop."59_people" + pop."1014_people" + pop."1519_people") >= 100
  AND r.sa4_name IN (
    'Sydney - City and Inner South',
    'Sydney - Eastern Suburbs',
    'Sydney - Blacktown'
  )
GROUP BY r.sa2_code, r.sa2_name, pop."04_people", pop."59_people", pop."1014_people", pop."1519_people"
ORDER BY schools_per_1000_young DESC;


-- Step 5: Points of Interest (POIs)
-- Counts health, education, service, and recreation-related POIs per SA2 (based on assignment categories).

SELECT 
  r.sa2_code,
  r.sa2_name,
  COUNT(*) AS num_pois
FROM selected_sa4_pois p
JOIN sa2_regions r 
  ON ST_Contains(r.geometry, p.geometry)
JOIN population_data pop 
  ON r.sa2_code = pop.sa2_code::text
WHERE pop.total_people >= 100
  AND p.category IN (
    -- Health
    'General Hospital', 'Childrens Hospital', 'Community Medical Centre', 
    'Psychiatric Hospital', 'Nursing Home', 'Ambulance Station',

    -- Education
    'Preschool', 'Primary School', 'High School', 'Combined Primary-Secondary School', 
    'Special School', 'Technical College', 'University', 'Academy',

    -- Essential Services
    'Post Office', 'Library', 'Shopping Centre', 'Local Government Chambers', 
    'Court House', 'Rubbish Depot', 'Pumping Station', 'Filtration Plant', 
    'Gas Facility', 'Transmission Station', 'Sewage Works', 'Fire Station', 
    'Police Station', 'SES Facility',

    -- Recreational
    'Park', 'Sports Centre', 'Sports Court', 'Sports Field', 'Swimming Pool Facility', 
    'Museum', 'Art Gallery', 'Zoo', 'Tourist Attraction', 'Tourist Information Centre', 
    'Golf Course', 'Lookout', 'Beach', 'Outdoor Theatre', 'Picnic Area', 'Marina', 
    'Racecourse', 'Dog Track', 'Motor Racing Track', 'Cycling Track', 
    'Athletics Track', 'Observatory', 'Showground'
  )
GROUP BY r.sa2_code, r.sa2_name
ORDER BY num_pois DESC;


-- Step 6: Combine all metrics
-- Joins all 4 indicators (businesses, stops, schools, POIs) into a single result for each SA2.

SELECT
  base.sa2_code,
  base.sa2_name,
  COALESCE(b.businesses_per_1000, 0) AS businesses_per_1000,
  COALESCE(s.num_stops, 0) AS num_stops,
  COALESCE(sc.schools_per_1000_young, 0) AS schools_per_1000_young,
  COALESCE(p.num_pois, 0) AS num_pois
FROM (
  SELECT DISTINCT sa2_code, sa2_name
  FROM sa2_regions
  WHERE sa4_name IN (
    'Sydney - City and Inner South',
    'Sydney - Eastern Suburbs',
    'Sydney - Blacktown'
  )
) base

LEFT JOIN (
  SELECT 
    b.sa2_code,
    SUM(b.total_businesses)::float / pop.total_people * 1000 AS businesses_per_1000
  FROM business_data b
  JOIN population_data pop ON b.sa2_code = pop.sa2_code
  JOIN sa2_regions r ON b.sa2_code::text = r.sa2_code
  WHERE pop.total_people >= 100
    AND r.sa4_name IN (
      'Sydney - City and Inner South',
      'Sydney - Eastern Suburbs',
      'Sydney - Blacktown'
    )
  GROUP BY b.sa2_code, pop.total_people
) b ON base.sa2_code = b.sa2_code::text

LEFT JOIN (
  SELECT 
    r.sa2_code,
    COUNT(*) AS num_stops
  FROM stops_data s
  JOIN sa2_regions r ON ST_Contains(r.geometry, ST_SetSRID(ST_MakePoint(s.stop_lon, s.stop_lat), 4326))
  JOIN population_data p ON r.sa2_code = p.sa2_code::text
  WHERE p.total_people >= 100
    AND r.sa4_name IN (
      'Sydney - City and Inner South',
      'Sydney - Eastern Suburbs',
      'Sydney - Blacktown'
    )
  GROUP BY r.sa2_code
) s ON base.sa2_code = s.sa2_code

LEFT JOIN (
  SELECT 
    r.sa2_code,
    COUNT(*)::float / (
      pop."04_people" + pop."59_people" + pop."1014_people" + pop."1519_people"
    ) * 1000 AS schools_per_1000_young
  FROM school_catchments_primary sc
  JOIN sa2_regions r ON ST_Intersects(sc.geometry, r.geometry)
  JOIN population_data pop ON r.sa2_code = pop.sa2_code::text
  WHERE (pop."04_people" + pop."59_people" + pop."1014_people" + pop."1519_people") >= 100
    AND r.sa4_name IN (
      'Sydney - City and Inner South',
      'Sydney - Eastern Suburbs',
      'Sydney - Blacktown'
    )
  GROUP BY r.sa2_code, pop."04_people", pop."59_people", pop."1014_people", pop."1519_people"
) sc ON base.sa2_code = sc.sa2_code

LEFT JOIN (
  SELECT 
    r.sa2_code,
    COUNT(*) AS num_pois
  FROM selected_sa4_pois p
  JOIN sa2_regions r ON ST_Contains(r.geometry, p.geometry)
  JOIN population_data pop ON r.sa2_code = pop.sa2_code::text
  WHERE pop.total_people >= 100
    AND p.category IN (
      'General Hospital', 'Childrens Hospital', 'Community Medical Centre', 
      'Psychiatric Hospital', 'Nursing Home', 'Ambulance Station',
      'Preschool', 'Primary School', 'High School', 'Combined Primary-Secondary School', 
      'Special School', 'Technical College', 'University', 'Academy',
      'Post Office', 'Library', 'Shopping Centre', 'Local Government Chambers', 
      'Court House', 'Rubbish Depot', 'Pumping Station', 'Filtration Plant', 
      'Gas Facility', 'Transmission Station', 'Sewage Works', 'Fire Station', 
      'Police Station', 'SES Facility',
      'Park', 'Sports Centre', 'Sports Court', 'Sports Field', 'Swimming Pool Facility', 
      'Museum', 'Art Gallery', 'Zoo', 'Tourist Attraction', 'Tourist Information Centre', 
      'Golf Course', 'Lookout', 'Beach', 'Outdoor Theatre', 'Picnic Area', 'Marina', 
      'Racecourse', 'Dog Track', 'Motor Racing Track', 'Cycling Track', 
      'Athletics Track', 'Observatory', 'Showground'
    )
  GROUP BY r.sa2_code
) p ON base.sa2_code = p.sa2_code

ORDER BY sa2_name;


-- Step 7: Z-score normalisation and sigmoid scoring
-- Normalises metrics with z-scores, sums them, and applies sigmoid function to produce a final well-resourced score (0–1)

CREATE TABLE well_resourced_scores AS
WITH combined AS (
  SELECT
    base.sa2_code,
    base.sa2_name,
    COALESCE(b.businesses_per_1000, 0) AS businesses_per_1000,
    COALESCE(s.num_stops, 0) AS num_stops,
    COALESCE(sc.schools_per_1000_young, 0) AS schools_per_1000_young,
    COALESCE(p.num_pois, 0) AS num_pois
  FROM (
    SELECT DISTINCT sa2_code, sa2_name
    FROM sa2_regions
    WHERE sa4_name IN (
      'Sydney - City and Inner South',
      'Sydney - Eastern Suburbs',
      'Sydney - Blacktown'
    )
  ) base
  LEFT JOIN (
    SELECT b.sa2_code, SUM(b.total_businesses)::float / pop.total_people * 1000 AS businesses_per_1000
    FROM business_data b
    JOIN population_data pop ON b.sa2_code = pop.sa2_code
    JOIN sa2_regions r ON b.sa2_code::text = r.sa2_code
    WHERE pop.total_people >= 100
      AND r.sa4_name IN (
        'Sydney - City and Inner South', 'Sydney - Eastern Suburbs', 'Sydney - Blacktown'
      )
    GROUP BY b.sa2_code, pop.total_people
  ) b ON base.sa2_code = b.sa2_code::text
  LEFT JOIN (
    SELECT r.sa2_code, COUNT(*) AS num_stops
    FROM stops_data s
    JOIN sa2_regions r ON ST_Contains(r.geometry, ST_SetSRID(ST_MakePoint(s.stop_lon, s.stop_lat), 4326))
    JOIN population_data p ON r.sa2_code = p.sa2_code::text
    WHERE p.total_people >= 100
      AND r.sa4_name IN (
        'Sydney - City and Inner South', 'Sydney - Eastern Suburbs', 'Sydney - Blacktown'
      )
    GROUP BY r.sa2_code
  ) s ON base.sa2_code = s.sa2_code
  LEFT JOIN (
    SELECT r.sa2_code,
      COUNT(*)::float / (
        pop."04_people" + pop."59_people" + pop."1014_people" + pop."1519_people"
      ) * 1000 AS schools_per_1000_young
    FROM school_catchments_primary sc
    JOIN sa2_regions r ON ST_Intersects(sc.geometry, r.geometry)
    JOIN population_data pop ON r.sa2_code = pop.sa2_code::text
    WHERE (pop."04_people" + pop."59_people" + pop."1014_people" + pop."1519_people") >= 100
      AND r.sa4_name IN (
        'Sydney - City and Inner South', 'Sydney - Eastern Suburbs', 'Sydney - Blacktown'
      )
    GROUP BY r.sa2_code, pop."04_people", pop."59_people", pop."1014_people", pop."1519_people"
  ) sc ON base.sa2_code = sc.sa2_code
  LEFT JOIN (
    SELECT r.sa2_code, COUNT(*) AS num_pois
    FROM selected_sa4_pois p
    JOIN sa2_regions r ON ST_Contains(r.geometry, p.geometry)
    JOIN population_data pop ON r.sa2_code = pop.sa2_code::text
    WHERE pop.total_people >= 100
      AND p.category IN (
        'General Hospital', 'Childrens Hospital', 'Community Medical Centre', 'Psychiatric Hospital',
        'Nursing Home', 'Ambulance Station', 'Preschool', 'Primary School', 'High School',
        'Combined Primary-Secondary School', 'Special School', 'Technical College', 'University', 'Academy',
        'Post Office', 'Library', 'Shopping Centre', 'Local Government Chambers', 'Court House', 'Rubbish Depot',
        'Pumping Station', 'Filtration Plant', 'Gas Facility', 'Transmission Station', 'Sewage Works',
        'Fire Station', 'Police Station', 'SES Facility', 'Park', 'Sports Centre', 'Sports Court', 'Sports Field',
        'Swimming Pool Facility', 'Museum', 'Art Gallery', 'Zoo', 'Tourist Attraction', 'Tourist Information Centre',
        'Golf Course', 'Lookout', 'Beach', 'Outdoor Theatre', 'Picnic Area', 'Marina', 'Racecourse', 'Dog Track',
        'Motor Racing Track', 'Cycling Track', 'Athletics Track', 'Observatory', 'Showground'
      )
    GROUP BY r.sa2_code
  ) p ON base.sa2_code = p.sa2_code
),
scored AS (
  SELECT 
    sa2_code,
    sa2_name,
    businesses_per_1000,
    num_stops,
    schools_per_1000_young,
    num_pois,

    (businesses_per_1000 - AVG(businesses_per_1000) OVER()) / NULLIF(STDDEV_POP(businesses_per_1000) OVER(), 0) AS z_businesses,
    (num_stops - AVG(num_stops) OVER()) / NULLIF(STDDEV_POP(num_stops) OVER(), 0) AS z_stops,
    (schools_per_1000_young - AVG(schools_per_1000_young) OVER()) / NULLIF(STDDEV_POP(schools_per_1000_young) OVER(), 0) AS z_schools,
    (num_pois - AVG(num_pois) OVER()) / NULLIF(STDDEV_POP(num_pois) OVER(), 0) AS z_pois,

    (
      (businesses_per_1000 - AVG(businesses_per_1000) OVER()) / NULLIF(STDDEV_POP(businesses_per_1000) OVER(), 0) +
      (num_stops - AVG(num_stops) OVER()) / NULLIF(STDDEV_POP(num_stops) OVER(), 0) +
      (schools_per_1000_young - AVG(schools_per_1000_young) OVER()) / NULLIF(STDDEV_POP(schools_per_1000_young) OVER(), 0) +
      (num_pois - AVG(num_pois) OVER()) / NULLIF(STDDEV_POP(num_pois) OVER(), 0)
    ) AS z_sum,

    1 / (1 + EXP(-(
      (businesses_per_1000 - AVG(businesses_per_1000) OVER()) / NULLIF(STDDEV_POP(businesses_per_1000) OVER(), 0) +
      (num_stops - AVG(num_stops) OVER()) / NULLIF(STDDEV_POP(num_stops) OVER(), 0) +
      (schools_per_1000_young - AVG(schools_per_1000_young) OVER()) / NULLIF(STDDEV_POP(schools_per_1000_young) OVER(), 0) +
      (num_pois - AVG(num_pois) OVER()) / NULLIF(STDDEV_POP(num_pois) OVER(), 0)
    ))) AS raw_score
  FROM combined
)
SELECT 
  s.sa2_code,
  s.sa2_name,
  r.sa4_name,
  ROUND(s.raw_score::numeric, 4) AS well_resourced_score
FROM scored s
JOIN sa2_regions r ON s.sa2_code = r.sa2_code;


-- Step 8: Indexing and creating keys.

-- Indexing

CREATE INDEX well_resourced_scores_sa2_idx
ON well_resourced_scores (sa2_name);;

-- Primary Keys
ALTER TABLE well_resourced_scores 
ADD COLUMN id SERIAL PRIMARY KEY;

-- Foreign Keys
ALTER TABLE well_resourced_scores 
ADD CONSTRAINT fk_well_resourced_scores_sa2 
FOREIGN KEY (sa2_name) 
REFERENCES sa2_regions(sa2_name);
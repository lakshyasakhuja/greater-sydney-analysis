-- DATA2001 Project - Greater Sydney Analysis
-- Authors: Lakshya Sakhuja (540863213), Ayush Arora (540906543) and Drishti Nehra (530685294)

-- USYD CODE CITATION ACKNOWLEDGEMENT
-- This file contains acknowledgements of code.

-- This SQL script contains setting up of all primary and foreign keys.

-- Primary Keys

ALTER TABLE population_data 
ADD CONSTRAINT population_data_pkey PRIMARY KEY (sa2_code);

ALTER TABLE income_data 
ADD CONSTRAINT income_data_pkey PRIMARY KEY (sa2_code);

ALTER TABLE sa2_regions 
ADD CONSTRAINT sa2_regions_pkey PRIMARY KEY (sa2_code);

ALTER TABLE sa2_greater_sydney 
ADD CONSTRAINT sa2_greater_sydney_pkey PRIMARY KEY (sa2_code);

ALTER TABLE school_catchments_primary 
ADD CONSTRAINT school_catchments_primary_pkey PRIMARY KEY (use_id);

ALTER TABLE school_catchments_secondary 
ADD CONSTRAINT school_catchments_secondary_pkey PRIMARY KEY (use_id);

ALTER TABLE school_catchments_future 
ADD CONSTRAINT school_catchments_future_pkey PRIMARY KEY (use_id);

ALTER TABLE stops_data 
ADD CONSTRAINT stops_data_pkey PRIMARY KEY (stop_id);

ALTER TABLE business_data 
ADD COLUMN id SERIAL PRIMARY KEY;

ALTER TABLE selected_sa4_pois 
ADD COLUMN id SERIAL PRIMARY KEY;


--Ensure type match: Convert bigint → text
ALTER TABLE business_data
ALTER COLUMN sa2_code TYPE TEXT;

ALTER TABLE income_data
ALTER COLUMN sa2_code TYPE TEXT;

ALTER TABLE population_data
ALTER COLUMN sa2_code TYPE TEXT;


-- Foreign Keys

ALTER TABLE sa2_regions 
ADD CONSTRAINT sa2_regions_sa2_name_key UNIQUE (sa2_name);

ALTER TABLE business_data 
ADD CONSTRAINT fk_business_data_sa2 
FOREIGN KEY (sa2_code) 
REFERENCES sa2_regions(sa2_code);

ALTER TABLE income_data 
ADD CONSTRAINT fk_income_data_sa2 
FOREIGN KEY (sa2_code) 
REFERENCES sa2_regions(sa2_code);

ALTER TABLE population_data 
ADD CONSTRAINT fk_population_data_sa2 
FOREIGN KEY (sa2_code) 
REFERENCES sa2_regions(sa2_code);

ALTER TABLE selected_sa4_pois 
ADD CONSTRAINT fk_selected_sa4_pois_sa2 
FOREIGN KEY (sa2_name) 
REFERENCES sa2_regions(sa2_name);

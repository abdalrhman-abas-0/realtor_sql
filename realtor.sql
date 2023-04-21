-- creating the data base
CREATE DATABASE realtor;

-- creating empty tables for houses, school, tax history & price history CSV files
-- and upload the data from each file into it's table

CREATE TABLE houses(
listing_page VARCHAR(500) PRIMARY KEY,
status VARCHAR(50),
price VARCHAR(50),
address VARCHAR(300),
bed_rooms VARCHAR(20),
bath_rooms VARCHAR(20),
parameter VARCHAR(30),
lot_area VARCHAR(50),
property_type VARCHAR(50),
display_period VARCHAR(30),
price_per_foot VARCHAR(30),
garage VARCHAR(30),
year_built VARCHAR(50),
neighborhood VARCHAR(50),
property_details VARCHAR(10000),
flood_factor_score INT,
provider_name VARCHAR(200),
provider_phone VARCHAR(20),
provider_page VARCHAR(500),
fire_factor_score INT
);

select *
from houses;

COPY houses(
listing_page,
status,
price,
address,
bed_rooms,
bath_rooms,
parameter,
lot_area,
property_type,
display_period,
price_per_foot,
garage,
year_built,
neighborhood,
property_details,
flood_factor_score,
provider_name,
provider_phone,
provider_page,
fire_factor_score
)
FROM 'C:\Users\realtor sql\input files\austin neighborhoods.csv'
DELIMITER ',' CSV HEADER;

SELECT * 
FROM houses
LIMIT(2);


CREATE TABLE tax_history(
Year VARCHAR (5),
Taxes VARCHAR (10),
Land VARCHAR (10),
added_to VARCHAR (1),
Additions VARCHAR (10),
equals VARCHAR(10),
Total_assessments VARCHAR(10),
profile VARCHAR(200)
);

COPY tax_history (
Year,
Taxes,
Land,
added_to,
Additions,
equals,
Total_assessments,
profile
)
FROM 'C:\Users\realtor sql\input files\tax history all.csv'
DELIMITER ',' CSV HEADER;

SELECT *
FROM tax_history
LIMIT 5;


CREATE TABLE price_history (
Date VARCHAR (20),
Event VARCHAR (30),
Price VARCHAR (10),
"Price/Sq_Ft" VARCHAR(10),
Source VARCHAR (20),
profile VARCHAR (200)
);

COPY price_history(
Date,
Event,
Price,
"Price/Sq_Ft",
Source,
profile
)
FROM 'C:\Users\realtor sql\input files\price history all.csv'
DELIMITER ',' CSV HEADER;

SELECT*
FROM price_history
LIMIT 10;

CREATE TABLE schools(
id VARCHAR (15),
name VARCHAR (100),
slug VARCHAR (250),
education_levels TEXT,
distance_in_miles  FLOAT (6),
student_teacher_ratio FLOAT (6),
rating FLOAT (6),
grades TEXT,
funding_type VARCHAR (20),
student_count FLOAT (50),
review_count INT,
parent_rating FLOAT (6),
assigned BOOLEAN ,
listing_page VARCHAR (200)
);


COPY schools(
id,
name,
slug,
education_levels,
distance_in_miles,
student_teacher_ratio,
rating,
grades,
funding_type,
student_count,
review_count,
parent_rating,
assigned,
listing_page
)
FROM 'C:\Users\realtor sql\input files\schools all.csv'
DELIMITER ',' CSV HEADER;

SELECT * 
FROM schools
LIMIT 100;

-- backup the school table table and create 2 tables out of it
-- 1- the schooling table which contains basic information about the schools relative to each house.
-- 2- the school table which contains detailed information about each school.

CREATE TABLE school_original
AS TABLE  schools;

CREATE TABLE schooling 
AS TABLE schools;

ALTER TABLE schooling
DROP COLUMN student_teacher_ratio,
DROP COLUMN rating,
DROP COLUMN student_count,
DROP COLUMN review_count,
DROP COLUMN parent_rating,
DROP COLUMN assigned,
DROP COLUMN slug;

ALTER TABLE schooling
RENAME COLUMN id TO school_id;

SELECT * 
FROM schooling;

ALTER TABLE schools
DROP COLUMN name,
DROP COLUMN education_levels,
DROP COLUMN distance_in_miles,
DROP COLUMN grades,
DROP COLUMN funding_type,
DROP COLUMN slug,
DROP COLUMN listing_page;

SELECT*
FROM schools;

-- clean the columns of houses table and renaming them appropriately
-- creating a copy table and clean it separately until it's in the right format and data types then will drop the 
-- original table and rename the copy table in the original name

CREATE TABLE houses_copy AS
	SELECT REGEXP_REPLACE(LTRIM(replace(price, ',',''),'$'), '\$\d+k', ''):: int AS price_,
		REPLACE(address,'Email agent', '') AS address_,
		NULLIF(year_built, 'not available')::int AS year_built_,
		REPLACE(bed_rooms, 'bed', '') :: int AS bed_rooms_,
		REPLACE(bath_rooms, 'bath', '') :: int AS bath_rooms_,
		NULLIF(REGEXP_REPLACE(garage, '(cars|car)',''), 'not available') :: int AS garage_car_capacity,
		NULLIF(LTRIM(price_per_foot,'$'),'not available') :: int AS price_per_foot_,
		REPLACE(parameter,'sqf','') :: int AS parameter_sqft,
		TO_JSONB(property_details) AS property_details_,
		CASE 
			WHEN lot_area ~ '\d+sqft' THEN REPLACE(REPLACE(NULLIF(REPLACE(lot_area, ',', ''), 'witout a lot!'),'lot', ''), 'sqft', '') :: float 
			WHEN lot_area ~ '\d+acre' THEN ROUND(REPLACE(REPLACE(NULLIF(REPLACE(lot_area, ',', ''), 'witout a lot!'),'lot', ''), 'acre', '') :: float * 43560)
		END AS lot_area_sqf,
		*
	FROM houses;


SELECT *
FROM houses_copy;

-- updating property details table to the correct json format
UPDATE houses_copy 
SET property_details_ = REPLACE(TRIM(property_details_:: text,'"'),'''','"'):: jsonb 

SELECT property_details_['Bathrooms']
FROM houses_copy;

-- checking the columns 
SELECT column_name, data_type, table_name, table_schema
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'houses_copy';

SELECT *
FROM houses_copy;

-- drop the original columns after checking that new columns are in the correct data types and format
ALTER TABLE houses_copy
DROP COLUMN price,
DROP COLUMN address,
DROP COLUMN year_built,
DROP COLUMN bed_rooms,
DROP COLUMN bath_rooms,
DROP COLUMN garage,
DROP COLUMN price_per_foot,
DROP COLUMN parameter,	
DROP COLUMN property_details,				  
DROP COLUMN lot_area;

-- rename the cleaned columns to the original column names
ALTER TABLE houses_copy
RENAME COLUMN price_ TO price;

ALTER TABLE houses_copy
RENAME COLUMN address_ TO address;

ALTER TABLE houses_copy
RENAME COLUMN year_built_ TO year_built;

ALTER TABLE houses_copy
RENAME COLUMN bed_rooms_ TO bed_rooms;

ALTER TABLE houses_copy
RENAME COLUMN bath_rooms_ TO bath_rooms;

ALTER TABLE houses_copy
RENAME COLUMN price_per_foot_ TO price_per_foot;

ALTER TABLE houses_copy
RENAME COLUMN property_details_ TO property_details;

SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'houses_copy';

SELECT *
FROM houses_copy;

-- dropping the original table and rename the cleaned copy of it by it's name
DROP TABLE houses;

ALTER TABLE houses_copy 
RENAME TO houses;

SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'houses';

SELECT *
FROM houses;

-- cleaning the tax_history table by using a copy and operating on it using update
SELECT *
FROM tax_history;

CREATE TABLE tax_copy AS
SELECT *
FROM tax_history;

UPDATE tax_copy 
SET total_assessments = REPLACE(REPLACE(total_assessments, '$',''),',','');

ALTER TABLE tax_copy
ALTER COLUMN total_assessments TYPE int
USING total_assessments :: integer;

UPDATE tax_copy 
SET land = NULLIF(land,'N/A');

UPDATE tax_copy
SET land = REPLACE(REPLACE(land ,'$', ''),',','');

ALTER TABLE tax_copy
ALTER COLUMN land TYPE int
USING land :: integer;

UPDATE tax_copy 
SET additions = NULLIF(additions, 'N/A');

UPDATE tax_copy
SET additions = REPLACE(REPLACE(additions ,'$', ''),',','');

ALTER TABLE tax_copy
ALTER COLUMN additions TYPE int
USING additions :: integer;

UPDATE tax_copy
SET taxes = REPLACE(REPLACE(taxes ,'$', ''),',','');

-- setting the columns to the correct data types

ALTER TABLE tax_copy
ALTER COLUMN taxes TYPE int
USING taxes :: integer;

ALTER TABLE tax_copy
ALTER COLUMN year TYPE int
USING year :: integer;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tax_copy';

-- dropping the unnecessary columns
ALTER TABLE tax_copy
DROP COLUMN added_to,
DROP COLUMN equals;

-- counting the records in both the original table and the cleaned copy table

SELECT count(*)
FROM tax_copy ;

SELECT count(*)
FROM tax_history ;

-- dropping the original table and renaming the cleaned copy table by it's name

DROP TABLE tax_history;

ALTER TABLE tax_copy 
RENAME TO tax_history;

-- cleansing the price history records using update 

SELECT *
FROM price_history;

UPDATE price_history
SET price = CASE 
	WHEN price LIKE '$%' THEN REPLACE(REPLACE(price ,'$', ''),',','')
	WHEN price LIKE '-' THEN NULLIF(price, '-')
END;

UPDATE price_history
SET "Price/Sq_Ft" = CASE 
	WHEN "Price/Sq_Ft" LIKE '$%' THEN REPLACE(REPLACE("Price/Sq_Ft" ,'$', ''),',','')
	WHEN "Price/Sq_Ft" LIKE '-' THEN NULLIF("Price/Sq_Ft", '-')
END;

-- renaming the price/sq_ft column to an easy to use format 

ALTER TABLE price_history 
RENAME COLUMN "Price/Sq_Ft" TO price_sqft;

-- changing the columns data types to the correct ones 

ALTER TABLE price_history
ALTER COLUMN price TYPE int
USING price :: integer;

ALTER TABLE price_history
ALTER COLUMN price_sqft TYPE int
USING price_sqft :: integer;

UPDATE price_history
SET date = date:: DATE;

ALTER TABLE price_history
ALTER COLUMN date TYPE DATE
USING date :: date;

-- changing the schools columns to the appropriate format

SELECT *
FROM schools;

ALTER TABLE schools
ALTER COLUMN "id" TYPE int
USING id:: integer;

SELECT *
FROM schooling;

-- creating a copy table as a backup 
CREATE TABLE schooling_copy AS 
SELECT *
FROM schooling;

ALTER TABLE schooling 
ALTER COLUMN school_id TYPE int
USING school_id :: integer;

UPDATE schooling 
SET education_levels = REPLACE(REPLACE(REPLACE(education_levels,'''','"'),'[','{'),']','}');

ALTER TABLE schooling
ALTER COLUMN education_levels TYPE text[]
USING education_levels::text[];

UPDATE SCHOOLING
SET grades = REPLACE(REPLACE(REPLACE(grades, '''','"'),'[','{'),']','}');

ALTER TABLE schooling
ALTER COLUMN grades TYPE text[]
USING grades::text[];

SELECT *
FROM schooling;

-- dropping the backup table after ensuring that the data are correctly formatted
DROP TABLE schooling_copy;

-- creating an index for the tables that have more than one record for each record in houses table (one to many)
-- to speed up the query process when working on them

CREATE INDEX idx_home_school
ON schooling(listing_page);

CREATE INDEX idx_home_taxes
ON tax_history(profile);

CREATE INDEX idx_home_history
ON price_history(profile);

-- dropping the duplicates from main tables 

-- schools table
ALTER TABLE schools 
RENAME TO schools_duplicates;

CREATE TABLE schools AS
SELECT DISTINCT *
FROM schools_duplicates;

SELECT * 
FROM schools;

-- dropping the schools_duplicates table as the schools table is cleaned properly now
DROP TABLE schools_duplicates;

-- creating primary key for schools and houses tables which have unique data for each record in them

ALTER TABLE schools
ADD CONSTRAINT pk_school PRIMARY KEY(id);

ALTER TABLE houses
ADD CONSTRAINT pk_house PRIMARY KEY(listing_page);

-- creating foreign key constraints for the necessary tables 

ALTER TABLE tax_history
ADD CONSTRAINT fk_listing_page FOREIGN KEY (profile) REFERENCES houses (listing_page);

ALTER TABLE price_history
ADD CONSTRAINT fk_listing_page FOREIGN KEY(profile) REFERENCES houses (listing_page);

ALTER TABLE schooling
ADD CONSTRAINT fk_houses FOREIGN KEY (listing_page) REFERENCES houses (listing_page);

ALTER TABLE schooling
ADD CONSTRAINT fk_school FOREIGN KEY (school_id) REFERENCES schools(id);


-- checking the no of records in all the derived tables
-- relative to the listing page unique value for each house

SELECT COUNT(*)
FROM houses;
-- 172 records

SELECT COUNT (DISTINCT profile)
FROM tax_history
-- 164 unique houses are listed 
-- missing 8 houses

SELECT COUNT (DISTINCT profile)
FROM price_history
-- 172 unique houses are listed 

SELECT COUNT (DISTINCT listing_page)
FROM schooling
-- 172 unique houses are listed 

-- dropping all the copy tables as the distinct listing page/profile matches 
-- the houses table row count except for the tax_history table.
-- also all the tables are cleansed, renamed properly & it's data is properly formatted 
DROP TABLE school_original;

-- filling the empty records in the tax history table to prevent errors 
-- when trying to join on the houses which have no tax history

CREATE TABLE tax_history_copy AS
SELECT *
FROM tax_history;

INSERT INTO tax_history_copy
SELECT th.year,
th.taxes,
th.land,
th.additions,
th.total_assessments,
houses.listing_page as profile
FROM houses
LEFT JOIN (
	SELECT DISTINCT *
	FROM tax_history
) th
ON th.profile = houses.listing_page
WHERE th.profile IS NULL;

select *
FROM tax_history_copy;

SELECT COUNT(*)
FROM tax_history;
-- 1126 over all record

SELECT COUNT(*)
FROM tax_history_copy;
-- 1126 over all record
-- 8 records are added for the missing houses successfully

-- dropping the original table and rename the copy table in it's name
DROP TABLE tax_history;

ALTER TABLE tax_history_copy
RENAME TO tax_history;

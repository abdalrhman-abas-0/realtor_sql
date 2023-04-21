-- testing the functionality of the data base by a real world scenario where a family of five with 3 kids in 
-- elementary schools where they require the following specifications for their next house:
-- 4 bed rooms at least 
-- 2 bath rooms at least
-- have a lot area of at least 600 sq/ft
-- be at most 1.5 miles away from an elementary school 
-- with a parent rating of over 4 stars and
-- public funding.



WITH h AS (
	SELECT * 
	FROM houses 
	WHERE bed_rooms >= 4
	AND bath_rooms >= 2
	AND lot_area_sqf >= 600
	AND garage_car_capacity >= 2
	AND price < 700000
	AND neighborhood LIKE 'Circle C Ranch%' 
	AND status LIKE 'For Sale'
	)

-- houses available under the specified requirements.
SELECT *
FROM h;

-- schools available for the given requirements.
SELECT s.*,
	schools.*
FROM h
JOIN schooling as s
	ON h.listing_page = s.listing_page
JOIN schools
	ON schools.id = s.school_id
WHERE 'elementary' = ANY(education_levels)
	AND parent_rating = 5
	AND funding_type = 'public'
	AND distance_in_miles < 1.5	;

-- investigating the tax history
SELECT t.*
FROM h
JOIN tax_history AS t
	ON h.listing_page = t.profile; 

-- investigating the price history
SELECT p.*
FROM h
JOIN price_history AS p
	ON h.listing_page = p.profile ;





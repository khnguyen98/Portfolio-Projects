/* 
Cleaning Data in SQL
*/

SELECT *
FROM LA_Airbnb_Calendar

SELECT *
FROM LA_Airbnb_Listing

-- Changing Calendar date format
ALTER TABLE LA_Airbnb_Calendar
ADD DateConverted date;

UPDATE LA_Airbnb_Calendar
SET DateConverted = CONVERT(date,date)

-- Checking whether update worked
SELECT DateConverted, CONVERT(date, date)
FROM LA_Airbnb_Calendar

-- Populating "Null" Bedroom data
SELECT SUM(CASE WHEN bedrooms IS NULL THEN 1 ELSE 0 END)
FROM LA_Airbnb_Listing

UPDATE LA_Airbnb_Listing
SET bedrooms = ISNULL(bedrooms, 0)

-- Changing "t" and "f" to "Yes" and "No" in "host_is_superhost" field 
SELECT DISTINCT(host_is_superhost), COUNT(host_is_superhost)
FROM LA_Airbnb_Listing
GROUP BY host_is_superhost

UPDATE LA_Airbnb_Listing
SET host_is_superhost = CASE WHEN host_is_superhost = 't' THEN 'Yes'
	   WHEN host_is_superhost = 'f' OR host_is_superhost IS NULL THEN 'No'
	   ELSE host_is_superhost
	   END

-- Joining tables as temp table
DROP TABLE IF EXISTS #LA_Airbnb
CREATE TABLE #LA_Airbnb
(
id float,
DateConverted date,
neighbourhood_cleansed nvarchar(255),
neighbourhood_group_cleansed nvarchar(255),
latitude float,
longitude float,
room_type nvarchar(255),
bedrooms float,
price money,
host_is_superhost nvarchar(255)
)

INSERT INTO #LA_Airbnb
SELECT listings.id, CONVERT(date, calendar.date) AS DateConverted, listings.neighbourhood_cleansed, listings.neighbourhood_group_cleansed, listings.latitude, listings.longitude, listings.room_type, listings.bedrooms, listings.price, listings.host_is_superhost
FROM LA_Airbnb_Listing as listings
JOIN LA_Airbnb_Calendar as calendar
ON calendar.listing_id = listings.id

SELECT * 
FROM #LA_Airbnb

-- Creating view for visualization 
CREATE VIEW LA_Airbnb AS
SELECT listings.id, CONVERT(date, calendar.date) AS DateConverted, listings.neighbourhood_cleansed, listings.neighbourhood_group_cleansed, listings.latitude, listings.longitude, listings.room_type, listings.bedrooms, listings.price, listings.host_is_superhost
FROM LA_Airbnb_Listing as listings
JOIN LA_Airbnb_Calendar as calendar
ON calendar.listing_id = listings.id
/* 
Cleaning Data in SQL
*/

SELECT *
FROM PortfolioProject..Nashville_Housing

-- Changing SaleDate format
ALTER TABLE PortfolioProject..Nashville_Housing
ADD SaleDateConverted Date;

UPDATE PortfolioProject..Nashville_Housing
SET SaleDateConverted = CONVERT(Date,SaleDate)

-- Checking whether update worked
SELECT SaleDateConverted, CONVERT(date, SaleDate)
FROM PortfolioProject..Nashville_Housing

-- Populate "NULL" Property address data.
-- Since there are duplicate cases of a property address and parcelID, we can use the parcelID to fill the NULL
SELECT ParcelID, PropertyAddress
FROM PortfolioProject..Nashville_Housing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..Nashville_Housing AS a
JOIN PortfolioProject..Nashville_Housing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..Nashville_Housing AS a
JOIN PortfolioProject..Nashville_Housing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Splitting Property Address into Multiple Columns (Address, City) using SUBSTRING and CHARINDEX
SELECT PropertyAddress
FROM PortfolioProject..Nashville_Housing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..Nashville_Housing

ALTER TABLE PortfolioProject..Nashville_Housing
ADD PropertySplitAddress NVARCHAR(255),
	PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject..Nashville_Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


-- Splitting Property Address into Multiple Columns (Address, City, State) using PARSENAME
-- PARSENAME looks for periods so must replace commas with periods
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM PortfolioProject..Nashville_Housing

ALTER TABLE PortfolioProject..Nashville_Housing
ADD OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject..Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Change "Y" and "N" to "Yes" and "No" in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..Nashville_Housing
GROUP BY SoldAsVacant
ORDER BY 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject..Nashville_Housing

UPDATE PortfolioProject..Nashville_Housing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-- Remove duplicates
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject..Nashville_Housing
--ORDER BY ParcelID
)

-- Checking for duplicates
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Remove unused columns

ALTER TABLE PortfolioProject..Nashville_Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


USE portfolioproject;

RENAME TABLE `nashville housing data for data cleaning` TO nashville_housing_data;

## Cleaning data in SQL queries
SELECT * 
FROM nashville_housing_data;

UPDATE nashville_housing_data
SET SaleDate = DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %d, %Y'), '%Y-%m-%d');

ALTER TABLE nashville_housing_data
MODIFY COLUMN SaleDate DATE;

##Populate PropertyAddress
SELECT *
FROM nashville_housing_data a
WHERE PropertyAddress IS NULL;

SELECT
    a.ParcelID,
	a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    IFNULL(NULLIF(a.PropertyAddress, ''), b.PropertyAddress) 
FROM
    nashville_housing_data a
JOIN
    nashville_housing_data b
ON
    a.ParcelID = b.ParcelID
AND
    a.UniqueID  <> b.UniqueID 
WHERE
    a.PropertyAddress = '';


UPDATE nashville_housing_data a
JOIN nashville_housing_data b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID 
SET a.PropertyAddress = IFNULL(NULLIF(a.PropertyAddress, ''), b.PropertyAddress) 
WHERE a.PropertyAddress = '';

#Breaking address into individual columns( Address, City, State)
SELECT *
FROM nashville_housing_data;
####WHERE PropertyAddress = '';

SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress))AS Address
FROM nashville_housing_data;

ALTER TABLE nashville_housing_data
ADD PropertySplitAddress VARCHAR(255);

UPDATE nashville_housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1);

ALTER TABLE nashville_housing_data
ADD PropertySplitCity VARCHAR(255);

UPDATE nashville_housing_data
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress));


SELECT 
    SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 1) AS Part1,
    SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 2), '.', -1) AS Part2,
    SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1) AS Part3
FROM nashville_housing_data;


ALTER TABLE nashville_housing_data
ADD OwnerSplitAddress VARCHAR(255);

UPDATE nashville_housing_data
SET OwnerSplitAddress = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 1);

ALTER TABLE nashville_housing_data
ADD OwnerSplitCity VARCHAR(255);

UPDATE nashville_housing_data
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 2), '.', -1);

ALTER TABLE nashville_housing_data
ADD OwnerSplitState VARCHAR(255);

UPDATE nashville_housing_data
SET OwnerSplitState = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1);


### Changing Y and N in SoldVacant to Yes and No
SELECT DISTINCT SoldAsVacant,
COUNT(SoldAsVacant)
FROM nashville_housing_data
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant ='N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM nashville_housing_data;

UPDATE nashville_housing_data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant ='N' THEN 'No'
    ELSE SoldAsVacant
    END;
    

### Remove Duplicates



WITH row_numCTE AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                              ORDER BY UniqueID) AS row_num
    FROM nashville_housing_data
)
SELECT *
FROM row_numCTE
WHERE row_num > 1;
####ORDER BY PropertyAddress;

### Using subqueries to delete the duplicates
DELETE FROM nashville_housing_data
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT *,
               DENSE_RANK() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                                  ORDER BY UniqueID) AS row_num
        FROM nashville_housing_data
    ) AS row_numCTE
    WHERE row_num > 1
);


#### Delete Unused Columns
SELECT *
FROM nashville_housing_data;
                
                
ALTER TABLE nashville_housing_data
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress



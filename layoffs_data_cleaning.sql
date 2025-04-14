
/* 
========================================================
DATA CLEANING SCRIPT FOR LAYOFFS DATA
Steps:
1. Create a working copy of the data
2. Identify and remove duplicates
3. Remove rows with null key fields
4. Reinsert clean data into a deduplicated version
========================================================
*/

/* STEP 1: Create a working copy of the layoffs table */
CREATE TABLE `copy_layoffs` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` DOUBLE DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Copy data from original table
INSERT INTO copy_layoffs
SELECT * FROM layoffs;


/* STEP 2: Identify duplicate records using ROW_NUMBER() */
WITH cte_duplicates AS (
  SELECT *, 
         ROW_NUMBER() OVER (
           PARTITION BY company, location, total_laid_off, percentage_laid_off, country, date
           ORDER BY company
         ) AS row_num
  FROM copy_layoffs
)
SELECT *
FROM cte_duplicates
WHERE row_num > 1
ORDER BY company, industry;


/* STEP 3: Remove rows with NULL values in key columns */
DELETE FROM copy_layoffs
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;


/* STEP 4: Spot check potential duplicates */
SELECT *
FROM copy_layoffs
WHERE company IN ('Cazoo', 'Hibob', 'Yahoo', 'Wildfire Studios')
ORDER BY company;


/* STEP 5: Create a new table with an added row number column */
CREATE TABLE `copy_layoffs2` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` DOUBLE DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL,
  `row_num` INT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


/* STEP 6: Insert data with ROW_NUMBER() to identify duplicates */
INSERT INTO copy_layoffs2
SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
         ORDER BY company
       ) AS row_num
FROM copy_layoffs;


/* STEP 7: Verify duplicates in the new table */
SELECT * 
FROM copy_layoffs2
WHERE row_num > 1;


/* STEP 8: Remove duplicate records from the original working table */
DELETE FROM copy_layoffs
WHERE (company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) IN (
  SELECT company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
  FROM copy_layoffs2
  WHERE row_num > 1
);


/* STEP 9: Final cleaned dataset */
SELECT *
FROM copy_layoffs;

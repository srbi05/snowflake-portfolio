-- ============================================================
-- Project  : Northside RMC BI Analytics
-- Author   : Raj
-- Script   : update_los_realistic.sql
-- Purpose  : Populate LOS_REALISTIC column in SNOW_ADT_FACT
--            with clinically realistic length-of-stay values
--            distributed by unit type.
-- Created  : June 2025
--
-- Why this exists:
--   Power BI DirectQuery does not support volatile DAX functions
--   like RANDBETWEEN() — they are evaluated at query time and
--   blocked in DirectQuery mode. The correct solution is to
--   compute this column at the Snowflake layer using UNIFORM()
--   which runs once at UPDATE time and stores static values.
--
-- Real-world equivalent:
--   In production, LOS_REALISTIC would be replaced by actual
--   LOS computed from ADMIT_DATE and DISCHARGE_DATE in the
--   EMR system. This transformation simulates that for the
--   synthetic dataset.
--
-- Realistic LOS benchmarks (ALOS by unit, US hospitals 2023):
--   ICU          : 14-22 days
--   Oncology     : 12-18 days
--   Orthopedics  :  6-10 days
--   General      :  4-8  days
--   Pediatrics   :  3-6  days
--   Maternity    :  2-4  days
--   ER           :  1-2  days
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA PUBLIC;
USE WAREHOUSE ANALYTICS_WH;

-- Step 1: Verify column exists (added during table creation)
-- If not present, uncomment the line below:
-- ALTER TABLE SNOW_ADT_FACT ADD COLUMN IF NOT EXISTS LOS_REALISTIC NUMBER;

-- Step 2: Update with unit-specific realistic LOS ranges
-- UNIFORM(low, high, RANDOM()) generates a random integer
-- in [low, high] inclusive — stored as a static value
UPDATE SNOW_ADT_FACT
SET LOS_REALISTIC =
    CASE UNIT
        WHEN 'ICU'          THEN UNIFORM(14, 22, RANDOM())
        WHEN 'Oncology'     THEN UNIFORM(12, 18, RANDOM())
        WHEN 'Orthopedics'  THEN UNIFORM(6,  10, RANDOM())
        WHEN 'General'      THEN UNIFORM(4,   8, RANDOM())
        WHEN 'Pediatrics'   THEN UNIFORM(3,   6, RANDOM())
        WHEN 'Maternity'    THEN UNIFORM(2,   4, RANDOM())
        WHEN 'ER'           THEN UNIFORM(1,   2, RANDOM())
        ELSE                     UNIFORM(3,  10, RANDOM())
    END;

-- Step 3: Verify the distribution looks clinically realistic
-- ICU should be highest, ER should be lowest
SELECT
    UNIT,
    ROUND(AVG(LOS_REALISTIC), 1)    AS AVG_LOS,
    MIN(LOS_REALISTIC)              AS MIN_LOS,
    MAX(LOS_REALISTIC)              AS MAX_LOS,
    COUNT(*)                        AS PATIENT_COUNT
FROM SNOW_ADT_FACT
GROUP BY UNIT
ORDER BY AVG_LOS DESC;

-- Expected output:
-- ICU          ~18.0   14   22   n
-- Oncology     ~15.0   12   18   n
-- Orthopedics  ~ 8.0    6   10   n
-- General      ~ 6.0    4    8   n
-- Pediatrics   ~ 4.5    3    6   n
-- Maternity    ~ 3.0    2    4   n
-- ER           ~ 1.5    1    2   n

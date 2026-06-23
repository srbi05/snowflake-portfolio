-- ============================================================
-- Project  : Northside RMC BI Analytics
-- Author   : Raj
-- Script   : incremental_refresh.sql
-- Purpose  : Configure Snowflake tables to support Power BI
--            incremental refresh using PARTITION_MONTH column.
-- Created  : June 2025
--
-- Problem without incremental refresh:
--   Power BI Import mode refreshes the entire table on every
--   scheduled refresh. For a hospital ADT table with 3 years
--   of data (~1M+ rows), a full refresh takes 45+ minutes
--   and fails during business hours due to memory limits.
--
-- Solution:
--   1. Add PARTITION_MONTH column (YYYY-MM format)
--   2. In Power BI, define RangeStart and RangeEnd parameters
--   3. Apply filter on PARTITION_MONTH in Power Query
--   4. Configure: store 12 months, refresh last 1 month only
--   Result: Refresh time drops from ~45 min to ~4 min
--
-- Power BI setup steps (documented here for team reference):
--   a. In Power Query, create parameters:
--      RangeStart = DateTime type
--      RangeEnd   = DateTime type
--   b. Filter ADMIT_DATE >= RangeStart AND < RangeEnd
--   c. In Power BI Desktop: Table > Incremental refresh
--      Store data: 12 months
--      Refresh data: 1 month
--   d. Publish to Power BI Service to activate
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA PUBLIC;
USE WAREHOUSE ANALYTICS_WH;

-- ─────────────────────────────────────────────────────────────
-- Step 1: Ensure PARTITION_MONTH is populated correctly
-- Format must be YYYY-MM to sort chronologically as string
-- ─────────────────────────────────────────────────────────────

-- Populate for ADT_FACT from ADMIT_DATE
UPDATE SNOW_ADT_FACT
SET PARTITION_MONTH = TO_VARCHAR(ADMIT_DATE, 'YYYY-MM')
WHERE PARTITION_MONTH IS NULL
  AND ADMIT_DATE IS NOT NULL;

-- Populate for REVENUE_FACT from SERVICE_DATE
UPDATE SNOW_REVENUE_FACT
SET PARTITION_MONTH = TO_VARCHAR(SERVICE_DATE, 'YYYY-MM')
WHERE PARTITION_MONTH IS NULL
  AND SERVICE_DATE IS NOT NULL;

-- ─────────────────────────────────────────────────────────────
-- Step 2: Verify partition distribution
-- You want roughly even row counts per month for stable refresh
-- ─────────────────────────────────────────────────────────────

SELECT
    'ADT_FACT'          AS SOURCE_TABLE,
    PARTITION_MONTH,
    COUNT(*)            AS ROW_COUNT
FROM SNOW_ADT_FACT
WHERE PARTITION_MONTH IS NOT NULL
GROUP BY PARTITION_MONTH
ORDER BY PARTITION_MONTH DESC;

SELECT
    'REVENUE_FACT'      AS SOURCE_TABLE,
    PARTITION_MONTH,
    COUNT(*)            AS ROW_COUNT
FROM SNOW_REVENUE_FACT
WHERE PARTITION_MONTH IS NOT NULL
GROUP BY PARTITION_MONTH
ORDER BY PARTITION_MONTH DESC;

-- ─────────────────────────────────────────────────────────────
-- Step 3: Create a helper view for the most recent month only
-- Used to test that Power BI incremental refresh is working
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW VW_ADT_CURRENT_MONTH AS
SELECT *
FROM SNOW_ADT_FACT
WHERE PARTITION_MONTH = TO_VARCHAR(CURRENT_DATE, 'YYYY-MM');

-- Confirm
SELECT COUNT(*) AS CURRENT_MONTH_PATIENTS FROM VW_ADT_CURRENT_MONTH;

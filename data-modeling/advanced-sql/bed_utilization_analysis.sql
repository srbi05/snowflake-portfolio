-- ================================================
-- Bed Utilization Analysis
-- Business Goal: Monitor occupancy vs target
-- capacity by floor, unit, and bed type
-- ================================================

-- 1. Occupied Beds vs Capacity by Unit
SELECT
    b.UNIT,
    b.BED_TYPE,
    b.ICU_FLAG,
    b.TOTAL_CAPACITY,
    b.TARGET_OCC_PCT,
    COUNT(a.BED_ID)                                         AS CURRENTLY_OCCUPIED,
    ROUND(COUNT(a.BED_ID) * 100.0 / b.TOTAL_CAPACITY, 1)   AS ACTUAL_OCC_PCT,
    ROUND(
        COUNT(a.BED_ID) * 100.0 / b.TOTAL_CAPACITY 
        - b.TARGET_OCC_PCT, 1
    )                                                       AS OCC_VS_TARGET_VARIANCE
FROM SNOW_BED_MASTER b
LEFT JOIN SNOW_ADT_FACT a
    ON  b.BED_ID = a.BED_ID
    AND a.DISCHARGE_DATE IS NULL   -- Currently admitted patients
GROUP BY b.UNIT, b.BED_TYPE, b.ICU_FLAG, b.TOTAL_CAPACITY, b.TARGET_OCC_PCT
ORDER BY ACTUAL_OCC_PCT DESC;


-- 2. ICU vs Non-ICU Utilization Summary
SELECT
    ICU_FLAG,
    SUM(TOTAL_CAPACITY)                                      AS TOTAL_BEDS,
    COUNT(a.BED_ID)                                          AS OCCUPIED_BEDS,
    ROUND(COUNT(a.BED_ID) * 100.0 / SUM(b.TOTAL_CAPACITY), 1) AS OCCUPANCY_PCT
FROM SNOW_BED_MASTER b
LEFT JOIN SNOW_ADT_FACT a
    ON  b.BED_ID = a.BED_ID
    AND a.DISCHARGE_DATE IS NULL
GROUP BY ICU_FLAG;


-- 3. Floor-Level Capacity Planning
SELECT
    FLOOR,
    COUNT(DISTINCT BED_ID)   AS TOTAL_BEDS,
    SUM(TOTAL_CAPACITY)      AS TOTAL_CAPACITY,
    AVG(TARGET_OCC_PCT)      AS AVG_TARGET_OCC_PCT,
    COUNT(DISTINCT UNIT)     AS UNITS_ON_FLOOR
FROM SNOW_BED_MASTER
GROUP BY FLOOR
ORDER BY FLOOR;

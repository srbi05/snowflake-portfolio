-- ================================================
-- Length of Stay & Readmission Analysis
-- Business Goal: Reduce LOS and identify high-risk
-- readmission patterns by unit and diagnosis
-- ================================================

-- 1. Average LOS by Unit with Readmission Rate
SELECT
    UNIT,
    COUNT(PATIENT_ID)                                              AS TOTAL_ADMISSIONS,
    ROUND(AVG(LOS_REALISTIC), 1)                                   AS AVG_LOS_DAYS,
    SUM(READMISSION_FLAG)                                          AS TOTAL_READMISSIONS,
    ROUND(SUM(READMISSION_FLAG) * 100.0 / COUNT(PATIENT_ID), 2)   AS READMISSION_RATE_PCT
FROM SNOW_ADT_FACT
GROUP BY UNIT
ORDER BY READMISSION_RATE_PCT DESC;


-- 2. Readmission Patients — Back Within 30 Days
SELECT
    a.PATIENT_ID,
    a.ADMIT_DATE                                    AS FIRST_ADMIT,
    a.DISCHARGE_DATE                                AS FIRST_DISCHARGE,
    b.ADMIT_DATE                                    AS READMIT_DATE,
    DATEDIFF('day', a.DISCHARGE_DATE, b.ADMIT_DATE) AS DAYS_BETWEEN,
    a.UNIT,
    a.ADMIT_REASON
FROM SNOW_ADT_FACT a
JOIN SNOW_ADT_FACT b
    ON  a.PATIENT_ID = b.PATIENT_ID
    AND b.ADMIT_DATE > a.DISCHARGE_DATE
    AND DATEDIFF('day', a.DISCHARGE_DATE, b.ADMIT_DATE) <= 30
ORDER BY DAYS_BETWEEN;


-- 3. LOS Outliers — Patients Staying 2x the Unit Average
WITH UNIT_AVG AS (
    SELECT
        UNIT,
        AVG(LOS_REALISTIC) AS AVG_LOS
    FROM SNOW_ADT_FACT
    GROUP BY UNIT
)
SELECT
    a.PATIENT_ID,
    a.UNIT,
    a.LOS_REALISTIC,
    ROUND(u.AVG_LOS, 1)              AS UNIT_AVG_LOS,
    ROUND(a.LOS_REALISTIC / u.AVG_LOS, 1) AS LOS_MULTIPLIER,
    a.ADMIT_REASON,
    a.INSURANCE_TYPE
FROM SNOW_ADT_FACT a
JOIN UNIT_AVG u ON a.UNIT = u.UNIT
WHERE a.LOS_REALISTIC > (u.AVG_LOS * 2)
ORDER BY LOS_MULTIPLIER DESC;


-- 4. Monthly Admission Trend by Unit
SELECT
    PARTITION_MONTH,
    UNIT,
    COUNT(PATIENT_ID)        AS TOTAL_ADMISSIONS,
    ROUND(AVG(LOS_REALISTIC), 1) AS AVG_LOS
FROM SNOW_ADT_FACT
GROUP BY PARTITION_MONTH, UNIT
ORDER BY PARTITION_MONTH, UNIT;

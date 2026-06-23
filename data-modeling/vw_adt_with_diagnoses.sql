-- ============================================================
-- Project  : Northside RMC BI Analytics
-- Author   : Raj
-- Object   : VW_ADT_WITH_DIAGNOSES
-- Type     : View
-- Purpose  : Flatten the VARIANT JSON column DIAGNOSIS_CODES_JSON
--            from SNOW_ADT_FACT into one row per diagnosis code
--            per patient. This view is consumed directly by
--            Power BI via DirectQuery — Power Query never
--            touches the raw JSON.
-- Created  : June 2025
--
-- Why flatten in Snowflake and not Power Query?
--   Parsing VARIANT/JSON inside Power Query on millions of rows
--   causes severe memory and timeout issues. Snowflake handles
--   semi-structured data natively with LATERAL FLATTEN,
--   making this the correct architectural pattern.
--
-- Source JSON structure (per patient):
--   {"codes": ["I21.0", "J18.9"], "primary": "I21.0"}
--
-- Output grain: One row per diagnosis code per patient
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA PUBLIC;

CREATE OR REPLACE VIEW VW_ADT_WITH_DIAGNOSES AS

SELECT
    a.PATIENT_ID,
    a.ADMIT_DATE,
    a.DISCHARGE_DATE,
    a.UNIT,
    a.BED_ID,
    a.ADMIT_REASON,
    a.DISCHARGE_REASON,
    a.ATTENDING_DOCTOR_ID,
    a.INSURANCE_TYPE,
    a.LOS_DAYS,
    a.LOS_REALISTIC,
    a.READMISSION_FLAG,
    a.PARTITION_MONTH,

    -- Flatten array of diagnosis codes from VARIANT JSON
    d.value::STRING                                     AS DIAGNOSIS_CODE,

    -- Extract primary diagnosis separately for filtering
    TRY_PARSE_JSON(a.DIAGNOSIS_CODES_JSON):primary::STRING AS PRIMARY_DIAGNOSIS,

    -- Flag whether this row is the primary diagnosis
    CASE
        WHEN d.value::STRING = TRY_PARSE_JSON(a.DIAGNOSIS_CODES_JSON):primary::STRING
        THEN 'Y'
        ELSE 'N'
    END                                                 AS IS_PRIMARY_FLAG

FROM
    SNOW_ADT_FACT a,

    -- LATERAL FLATTEN expands the JSON array into individual rows
    -- TRY_PARSE_JSON is used defensively in case any rows have malformed JSON
    LATERAL FLATTEN(
        input => TRY_PARSE_JSON(a.DIAGNOSIS_CODES_JSON):codes
    ) d

WHERE
    -- Exclude rows where JSON is NULL or malformed
    TRY_PARSE_JSON(a.DIAGNOSIS_CODES_JSON) IS NOT NULL;

-- ─────────────────────────────────────────────────────────────
-- Preview the flattened output
-- Expected: multiple rows per PATIENT_ID (one per diagnosis)
-- ─────────────────────────────────────────────────────────────
SELECT
    PATIENT_ID,
    ADMIT_DATE,
    UNIT,
    DIAGNOSIS_CODE,
    PRIMARY_DIAGNOSIS,
    IS_PRIMARY_FLAG
FROM VW_ADT_WITH_DIAGNOSES
LIMIT 20;

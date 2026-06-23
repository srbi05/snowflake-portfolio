-- ============================================================
-- Project  : Northside RMC BI Analytics
-- Author   : Raj
-- Script   : create_tables.sql
-- Purpose  : DDL for all 4 source tables in HOSPITAL_DW
-- Created  : June 2025
-- Notes    : DIAGNOSIS_CODES_JSON uses VARIANT type to store
--            semi-structured JSON from the EMR system.
--            PARTITION_MONTH enables incremental refresh in
--            Power BI without full table scans.
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA PUBLIC;
USE WAREHOUSE ANALYTICS_WH;

-- ─────────────────────────────────────────────────────────────
-- TABLE 1: SNOW_ADT_FACT
-- Source  : EMR ADT System (Admissions, Discharges, Transfers)
-- Grain   : One row per patient admission episode
-- Key     : PATIENT_ID (non-unique — patients can be readmitted)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TABLE SNOW_ADT_FACT (
    PATIENT_ID              VARCHAR(10)     NOT NULL,
    ADMIT_DATE              DATE            NOT NULL,
    ADMIT_TIME              VARCHAR(5),
    DISCHARGE_DATE          DATE,                       -- NULL = patient still admitted
    DISCHARGE_TIME          VARCHAR(5),
    UNIT                    VARCHAR(20)     NOT NULL,
    BED_ID                  VARCHAR(15),
    ADMIT_REASON            VARCHAR(50),
    DISCHARGE_REASON        VARCHAR(30),
    ATTENDING_DOCTOR_ID     VARCHAR(10),
    INSURANCE_TYPE          VARCHAR(20),
    LOS_DAYS                NUMBER,                     -- NULL for active patients
    DIAGNOSIS_CODES_JSON    VARIANT,                    -- Semi-structured JSON from EMR
    READMISSION_FLAG        NUMBER(1),                  -- 1 = readmission within 30 days
    PARTITION_MONTH         VARCHAR(7),                 -- Format: YYYY-MM (for incremental refresh)
    LOS_REALISTIC           NUMBER                      -- Unit-adjusted LOS for analytics
)
COMMENT = 'Core patient admission/discharge/transfer fact table. Source: EMR ADT system.';

-- ─────────────────────────────────────────────────────────────
-- TABLE 2: SNOW_BED_MASTER
-- Source  : Hospital Operations (static reference data)
-- Grain   : One row per unit
-- Key     : BED_ID / UNIT
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TABLE SNOW_BED_MASTER (
    BED_ID                  VARCHAR(15)     NOT NULL,
    UNIT                    VARCHAR(20)     NOT NULL,
    FLOOR                   NUMBER,
    BED_TYPE                VARCHAR(25),
    TOTAL_CAPACITY          NUMBER          NOT NULL,
    TARGET_OCC_PCT          NUMBER,                     -- Target occupancy percentage (numeric, no % symbol)
    ICU_FLAG                VARCHAR(3)                  -- Yes/No
)
COMMENT = 'Unit and bed capacity reference table. Source: Hospital Operations.';

-- ─────────────────────────────────────────────────────────────
-- TABLE 3: SNOW_DISCHARGE_DELAYS
-- Source  : Nursing System (daily CSV upload)
-- Grain   : One row per delay event (patient can have multiple)
-- Key     : PATIENT_ID (Many-to-One → SNOW_ADT_FACT)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TABLE SNOW_DISCHARGE_DELAYS (
    PATIENT_ID              VARCHAR(10)     NOT NULL,
    UNIT                    VARCHAR(20),
    EXPECTED_DISCHARGE      DATE,
    ACTUAL_DISCHARGE        DATE,
    DELAY_MINUTES           NUMBER,
    DELAY_REASON_CODE       VARCHAR(10),
    NURSE_ID                VARCHAR(8),
    ESCALATED_FLAG          VARCHAR(3)                  -- Yes if delay > 300 minutes
)
COMMENT = 'Discharge delay tracking. One patient can have multiple delay records. Source: Nursing system.';

-- ─────────────────────────────────────────────────────────────
-- TABLE 4: SNOW_REVENUE_FACT
-- Source  : Billing System
-- Grain   : One row per insurance claim
-- Key     : CLAIM_ID (unique), PATIENT_ID (Many-to-One → ADT_FACT)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TABLE SNOW_REVENUE_FACT (
    CLAIM_ID                VARCHAR(10)     NOT NULL,
    PATIENT_ID              VARCHAR(10)     NOT NULL,
    SERVICE_DATE            DATE,
    SUBMISSION_DATE         DATE,
    INSURANCE_TYPE          VARCHAR(20),
    BILLED_AMOUNT           NUMBER(10,2),               -- No $ symbol — numeric only
    ALLOWED_AMOUNT          NUMBER(10,2),
    PAID_AMOUNT             NUMBER(10,2),
    DENIAL_CODE             VARCHAR(10),
    DENIAL_REASON           VARCHAR(60),
    CLAIM_STATUS            VARCHAR(20),               -- Paid / Denied / Pending / Partially Paid
    DAYS_TO_PAYMENT         NUMBER,
    PARTITION_MONTH         VARCHAR(7)                  -- Format: YYYY-MM (for incremental refresh)
)
COMMENT = 'Insurance claims and revenue tracking. Source: Hospital billing system.';

-- ─────────────────────────────────────────────────────────────
-- Verify all tables created
-- ─────────────────────────────────────────────────────────────
SHOW TABLES IN SCHEMA PUBLIC;

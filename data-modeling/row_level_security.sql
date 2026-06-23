-- ============================================================
-- Project  : Northside RMC BI Analytics
-- Author   : Raj
-- Script   : row_level_security.sql
-- Purpose  : Define Row-Level Security roles so each nursing
--            unit head sees only their floor's data in Power BI.
-- Created  : June 2025
--
-- Architecture note:
--   RLS in this project is implemented at the Power BI layer
--   (not Snowflake) because:
--   1. The client uses Azure AD for identity management
--   2. Power BI RLS integrates natively with Azure AD groups
--   3. Snowflake RLS (row access policies) would require
--      additional licensing not available on free trial
--
--   This script documents the Snowflake-side user/role setup
--   that would be needed in a production environment where
--   RLS is enforced at the data warehouse layer.
--
-- Power BI RLS setup (implemented in Power BI Desktop):
--   Modeling > Manage Roles > New Role
--   Role: ICU_Nurse    → Filter: ADT_Fact[UNIT] = "ICU"
--   Role: ER_Nurse     → Filter: ADT_Fact[UNIT] = "ER"
--   Role: COO          → No filter (sees all units)
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA PUBLIC;
USE WAREHOUSE ANALYTICS_WH;

-- ─────────────────────────────────────────────────────────────
-- Snowflake roles for production RLS
-- (Reference only — implement in production Snowflake account)
-- ─────────────────────────────────────────────────────────────

-- Create unit-specific roles
CREATE ROLE IF NOT EXISTS HOSPITAL_ICU_ANALYST
    COMMENT = 'Read access to ICU unit data only';

CREATE ROLE IF NOT EXISTS HOSPITAL_ER_ANALYST
    COMMENT = 'Read access to ER unit data only';

CREATE ROLE IF NOT EXISTS HOSPITAL_GENERAL_ANALYST
    COMMENT = 'Read access to General ward data only';

CREATE ROLE IF NOT EXISTS HOSPITAL_COO
    COMMENT = 'Full read access to all units — executive role';

-- Grant warehouse usage to all roles
GRANT USAGE ON WAREHOUSE ANALYTICS_WH TO ROLE HOSPITAL_ICU_ANALYST;
GRANT USAGE ON WAREHOUSE ANALYTICS_WH TO ROLE HOSPITAL_ER_ANALYST;
GRANT USAGE ON WAREHOUSE ANALYTICS_WH TO ROLE HOSPITAL_GENERAL_ANALYST;
GRANT USAGE ON WAREHOUSE ANALYTICS_WH TO ROLE HOSPITAL_COO;

-- Grant database and schema usage
GRANT USAGE ON DATABASE HOSPITAL_DW TO ROLE HOSPITAL_COO;
GRANT USAGE ON SCHEMA HOSPITAL_DW.PUBLIC TO ROLE HOSPITAL_COO;
GRANT SELECT ON ALL TABLES IN SCHEMA HOSPITAL_DW.PUBLIC TO ROLE HOSPITAL_COO;
GRANT SELECT ON ALL VIEWS IN SCHEMA HOSPITAL_DW.PUBLIC TO ROLE HOSPITAL_COO;

-- ─────────────────────────────────────────────────────────────
-- Snowflake Row Access Policy (production pattern)
-- Restricts ADT_FACT rows by UNIT based on current role
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE ROW ACCESS POLICY HOSPITAL_UNIT_ACCESS_POLICY
AS (UNIT VARCHAR) RETURNS BOOLEAN ->
    CASE
        -- COO and admin see everything
        WHEN CURRENT_ROLE() IN ('HOSPITAL_COO', 'SYSADMIN', 'ACCOUNTADMIN')
            THEN TRUE
        -- Unit-specific roles see only their unit
        WHEN CURRENT_ROLE() = 'HOSPITAL_ICU_ANALYST'     AND UNIT = 'ICU'         THEN TRUE
        WHEN CURRENT_ROLE() = 'HOSPITAL_ER_ANALYST'      AND UNIT = 'ER'          THEN TRUE
        WHEN CURRENT_ROLE() = 'HOSPITAL_GENERAL_ANALYST' AND UNIT = 'General'     THEN TRUE
        -- Default: deny
        ELSE FALSE
    END;

-- Apply policy to the fact table
ALTER TABLE SNOW_ADT_FACT
ADD ROW ACCESS POLICY HOSPITAL_UNIT_ACCESS_POLICY ON (UNIT);

-- ─────────────────────────────────────────────────────────────
-- Verify policy is applied
-- ─────────────────────────────────────────────────────────────
SHOW ROW ACCESS POLICIES IN SCHEMA PUBLIC;

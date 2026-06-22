# Healthcare Data Warehouse — Snowflake Star Schema

## Overview
A production-grade Snowflake data warehouse built for hospital operations,
tracking patient admissions, bed management, discharge workflows, and 
revenue cycle management across a multi-unit health system.

## Business Problems Solved
- Track patient admissions, transfers, and discharges (ADT) in real time
- Monitor bed utilization and ICU capacity across floors and units
- Identify and escalate discharge delays to reduce Length of Stay (LOS)
- Analyze insurance claim denials and days-to-payment for revenue cycle teams
- Flatten nested JSON diagnosis codes for downstream BI reporting (Power BI / Tableau)

## Schema Design

### Fact Tables
| Table | Description |
|---|---|
| `SNOW_ADT_FACT` | Core admission/discharge/transfer events per patient |
| `SNOW_REVENUE_FACT` | Insurance claims, billed vs paid amounts, denial tracking |

### Dimension Tables
| Table | Description |
|---|---|
| `SNOW_BED_MASTER` | Bed inventory by unit, floor, type, and ICU flag |

### Supporting Tables
| Table | Description |
|---|---|
| `SNOW_DISCHARGE_DELAYS` | Delay tracking with reason codes, nurse assignment, escalation |

### Views
| View | Description |
|---|---|
| `VW_ADT_WITH_DIAGNOSES` | Flattens VARIANT JSON diagnosis codes using LATERAL FLATTEN |

## Key Snowflake Features Used
- `VARIANT` column with `TRY_PARSE_JSON` for semi-structured JSON diagnosis codes
- `LATERAL FLATTEN` to explode nested JSON arrays into rows
- Partition columns (`PARTITION_MONTH`) for query pruning and performance
- `ICU_FLAG`, `READMISSION_FLAG` for operational and clinical KPI tracking

## Tech Stack
- **Snowflake** — Data warehouse and transformation layer
- **Power BI / Tableau** — Reporting and dashboard layer
- **SQL** — DDL, views, and analytical queries

## Domain
Healthcare — Hospital Operations & Revenue Cycle Management

## Experience Level
18+ years in data engineering and analytics across healthcare data platforms

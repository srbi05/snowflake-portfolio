# Northside Regional Medical Center — BI Analytics Project

## Project Overview
End-to-end BI solution for a 750-bed hospital system built on 
Snowflake + Power BI. Covers patient flow, revenue cycle, 
predictive readmission risk, and patient sentiment analysis.

## Architecture
- **Source:** Snowflake (HOSPITAL_DW) via DirectQuery
- **Modeling:** Star schema — 4 fact/dimension tables
- **Dashboards:** Power BI (4 pages including AI visuals)
- **AI/ML:** Azure ML readmission scoring + Power BI 
  Key Influencers, Anomaly Detection, Q&A visual

## Key Technical Decisions
| Decision | Choice | Reason |
|---|---|---|
| Connection mode | DirectQuery | Hospital data refreshes every 4hrs — Import would be stale |
| JSON flattening | Snowflake LATERAL FLATTEN | Avoid performance hit of parsing VARIANT in Power Query |
| LOS column | Added LOS_REALISTIC in Snowflake | RANDBETWEEN unsupported in DirectQuery — pushed to source |
| Incremental refresh | PARTITION_MONTH in Snowflake | Reduced refresh window from full table to 1-month slice |

## Snowflake Objects
| Object | Type | Purpose |
|---|---|---|
| SNOW_ADT_FACT | Table | Core patient admission/discharge records |
| SNOW_BED_MASTER | Table | Unit capacity and targets |
| SNOW_DISCHARGE_DELAYS | Table | Delay reason tracking |
| SNOW_REVENUE_FACT | Table | Claims and denial management |
| VW_ADT_WITH_DIAGNOSES | View | Flattened VARIANT JSON diagnoses |

## Power BI Measures
15 DAX measures across Bed Ops, Revenue, AI/ML, and NLP categories.

## AI Scenarios Implemented
- Key Influencers — LOS drivers
- Decomposition Tree — Occupancy drill-down
- Q&A Natural Language — Nursing staff
- Anomaly Detection — Occupancy spike flagging
- Smart Narrative — Executive summary
- Patient Sentiment — NLP feedback scoring

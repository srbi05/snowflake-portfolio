-- ================================================
-- Revenue Cycle Analysis
-- Business Goal: Identify denial patterns and 
-- days-to-payment by insurance type
-- ================================================

-- 1. Denial Rate by Insurance Type
SELECT
    INSURANCE_TYPE,
    COUNT(CLAIM_ID)                                          AS TOTAL_CLAIMS,
    SUM(CASE WHEN CLAIM_STATUS = 'DENIED' THEN 1 ELSE 0 END) AS DENIED_CLAIMS,
    ROUND(
        SUM(CASE WHEN CLAIM_STATUS = 'DENIED' THEN 1 ELSE 0 END) * 100.0 
        / COUNT(CLAIM_ID), 2
    )                                                        AS DENIAL_RATE_PCT,
    ROUND(AVG(BILLED_AMOUNT), 2)                             AS AVG_BILLED,
    ROUND(AVG(PAID_AMOUNT), 2)                               AS AVG_PAID,
    ROUND(AVG(DAYS_TO_PAYMENT), 1)                           AS AVG_DAYS_TO_PAYMENT
FROM SNOW_REVENUE_FACT
GROUP BY INSURANCE_TYPE
ORDER BY DENIAL_RATE_PCT DESC;


-- 2. Top Denial Reasons Costing the Most Revenue
SELECT
    DENIAL_REASON,
    COUNT(CLAIM_ID)                AS TOTAL_DENIALS,
    ROUND(SUM(BILLED_AMOUNT), 2)   AS TOTAL_BILLED_LOST,
    ROUND(AVG(BILLED_AMOUNT), 2)   AS AVG_CLAIM_VALUE
FROM SNOW_REVENUE_FACT
WHERE CLAIM_STATUS = 'DENIED'
GROUP BY DENIAL_REASON
ORDER BY TOTAL_BILLED_LOST DESC
LIMIT 10;


-- 3. Monthly Revenue Trend — Billed vs Paid vs Variance
SELECT
    PARTITION_MONTH,
    ROUND(SUM(BILLED_AMOUNT), 2)              AS TOTAL_BILLED,
    ROUND(SUM(ALLOWED_AMOUNT), 2)             AS TOTAL_ALLOWED,
    ROUND(SUM(PAID_AMOUNT), 2)                AS TOTAL_PAID,
    ROUND(SUM(BILLED_AMOUNT - PAID_AMOUNT), 2) AS TOTAL_VARIANCE
FROM SNOW_REVENUE_FACT
GROUP BY PARTITION_MONTH
ORDER BY PARTITION_MONTH;


-- 4. Claims Aging — Days to Payment Buckets
SELECT
    INSURANCE_TYPE,
    SUM(CASE WHEN DAYS_TO_PAYMENT <= 30  THEN 1 ELSE 0 END) AS "0-30 Days",
    SUM(CASE WHEN DAYS_TO_PAYMENT <= 60
             AND DAYS_TO_PAYMENT > 30   THEN 1 ELSE 0 END) AS "31-60 Days",
    SUM(CASE WHEN DAYS_TO_PAYMENT <= 90
             AND DAYS_TO_PAYMENT > 60   THEN 1 ELSE 0 END) AS "61-90 Days",
    SUM(CASE WHEN DAYS_TO_PAYMENT > 90  THEN 1 ELSE 0 END) AS "90+ Days"
FROM SNOW_REVENUE_FACT
WHERE CLAIM_STATUS = 'PAID'
GROUP BY INSURANCE_TYPE
ORDER BY INSURANCE_TYPE;

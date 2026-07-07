CREATE DATABASE teleco_project;
USE teleco_project;

SELECT * FROM customer_churn LIMIT 10;

SELECT 
    COUNT(*) AS total_rows,       
    SUM(CASE WHEN TotalCharges IS NULL OR TRIM(TotalCharges) = '' THEN 1 ELSE 0 END) AS blank_total_charges
FROM customer_churn;

UPDATE customer_churn
SET TotalCharges = '0'
WHERE TRIM(TotalCharges) = '';

-- 1. Turn off Safe Updates temporarily
SET SQL_SAFE_UPDATES = 0;

-- 2. Fix the blank strings
UPDATE customer_churn
SET TotalCharges = '0'
WHERE TRIM(TotalCharges) = '';

-- 3. Turn Safe Updates back on
SET SQL_SAFE_UPDATES = 1;

-- 4. Convert the column to a proper number format
ALTER TABLE customer_churn
MODIFY COLUMN TotalCharges DOUBLE;

SELECT 
    Churn,
    COUNT(*) AS total_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM customer_churn
GROUP BY Churn;

SELECT 
    Churn,
    COUNT(*) AS total_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM customer_churn
GROUP BY Churn;

SELECT 
    InternetService, 
    TechSupport,
    COUNT(*) AS total_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS churn_rate_pct
FROM customer_churn
GROUP BY InternetService, TechSupport
ORDER BY churn_rate_pct DESC;

SELECT 
    CASE 
        WHEN tenure <= 12 THEN '0-12 months'
        WHEN tenure <= 24 THEN '13-24 months'
        WHEN tenure <= 48 THEN '25-48 months'
        ELSE '48+ months'
    END AS tenure_cohort,
    COUNT(*) AS total_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charge
FROM customer_churn
GROUP BY 1
ORDER BY 1;

WITH scored AS (
    SELECT *,
        (
            (CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END) +
            (CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END) +
            (CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END) +
            (CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END) +
            (CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END) +
            (CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END) +
            (CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END)
        ) AS service_count
    FROM customer_churn
)
SELECT 
    CASE 
        WHEN tenure < 12 AND service_count <= 2 THEN 'High Risk'
        WHEN tenure < 24 AND service_count <= 4 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_segment,
    COUNT(*) AS customers,
    ROUND(100.0 * SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS churn_rate_pct,
    ROUND(SUM(MonthlyCharges), 0) AS monthly_revenue_at_risk
FROM scored
GROUP BY 1
ORDER BY churn_rate_pct DESC;
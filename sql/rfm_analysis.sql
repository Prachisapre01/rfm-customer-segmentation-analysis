--step 1 append all monthly sales tables together 

CREATE OR REPLACE TABLE `rfmanalysis1111.sales.sales_2025` AS 
SELECT * FROM `rfmanalysis1111.sales.sales202501`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202502`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202503`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202504`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202505`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202506`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202507`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202508`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202509`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202510`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202511`
UNION ALL SELECT * FROM `rfmanalysis1111.sales.sales202512`;


--step 2 calculate regency, frequency and monetary, (r,f,m)ranks
--combine views with CTEs
CREATE OR REPLACE VIEW `rfmanalysis1111.sales.rfm_metrics` AS 
WITH current_date AS (
  SELECT DATE('2026-03-17') AS analysis_date
),
rfm AS (
  SELECT 
    CustomerID,
    MAX(OrderDate) AS last_order_date,
    date_diff((select analysis_date from current_date),MAX(OrderDate), DAY) AS recency,
    COUNT(*) AS frequency,
    SUM(OrderValue) AS monetary
  FROM `rfmanalysis1111.sales.sales_2025`
  GROUP BY CustomerID
)
SELECT 
  rfm.*,
  ROW_NUMBER() OVER(ORDER BY recency ASC) AS r_rank,
  ROW_NUMBER() OVER(ORDER BY frequency DESC) AS f_rank,
  ROW_NUMBER() OVER(ORDER BY monetary DESC) AS m_rank
FROM rfm;


--step 3 assigning decile (10 = best, 01 = worst)
CREATE OR REPLACE VIEW `rfmanalysis1111.sales.rfm_scores` AS
SELECT 
  *,
  NTILE(10) OVER(ORDER BY r_rank DESC) AS r_score,
  NTILE(10) OVER(ORDER BY f_rank DESC) AS f_score,
  NTILE(10) OVER(ORDER BY m_rank DESC) AS m_score
FROM `rfmanalysis1111.sales.rfm_metrics`;


--step 4 total scores
CREATE OR REPLACE VIEW `rfmanalysis1111.sales.rfm_total_scores` AS 
SELECT 
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  (r_score + f_score + m_score) AS rfm_total_score
FROM `rfmanalysis1111.sales.rfm_scores`
ORDER BY rfm_total_score DESC;


--step 5 BI ready rfm segments table 
CREATE OR REPLACE TABLE `rfmanalysis1111.sales.rfm_segments_final` AS 
SELECT 
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  rfm_total_score,
  CASE 
    WHEN rfm_total_score >= 27 THEN 'champions'                                 --27-30
    WHEN rfm_total_score >= 24 AND rfm_total_score < 27 THEN 'loyalCustomers'   --24-26
    WHEN rfm_total_score >= 21 AND rfm_total_score < 24 THEN 'potentialLoyals'  --21-23
    WHEN rfm_total_score >= 17 AND rfm_total_score < 21 THEN 'newCustomer'      --17-20  
    WHEN rfm_total_score >= 13 AND rfm_total_score < 17 THEN 'promising'        --13-16
    WHEN rfm_total_score >=9 AND rfm_total_score <13  THEN 'needAttention'      --9-12   
    WHEN rfm_total_score >= 5  AND rfm_total_score < 9  THEN 'atRisk'           --5-9
    ELSE 'lost/inactive' END AS customer_segment                                    
FROM `rfmanalysis1111.sales.rfm_total_scores`
ORDER BY rfm_total_score DESC;










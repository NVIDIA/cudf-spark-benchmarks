
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count
), DemographicsRisk AS (
    SELECT 
        total_sales,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_purchase_estimate < 50000 THEN 'Low Risk'
            WHEN cd.cd_purchase_estimate BETWEEN 50000 AND 100000 THEN 'Medium Risk'
            ELSE 'High Risk'
        END AS risk_level
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    dr.risk_level,
    COUNT(*) AS customer_count,
    AVG(dr.total_sales) AS avg_sales
FROM 
    DemographicsRisk dr
GROUP BY 
    dr.risk_level
ORDER BY 
    dr.risk_level;

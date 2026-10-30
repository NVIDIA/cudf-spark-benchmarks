
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_spend,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_transaction_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Demographics AS (
    SELECT 
        d.cd_demo_sk, 
        d.cd_gender, 
        d.cd_marital_status, 
        d.cd_education_status,
        d.cd_credit_rating,
        CASE 
            WHEN d.cd_dep_count IS NULL OR d.cd_dep_count = 0 THEN 'No Dependents'
            ELSE 'Has Dependents'
        END AS dependent_status
    FROM 
        customer_demographics d
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        SUM(cs.total_spend) AS total_spend,
        MAX(cs.store_transaction_count) AS max_store_transactions,
        MAX(cs.web_transaction_count) AS max_web_transactions
    FROM 
        CustomerSales cs
    GROUP BY 
        cs.c_customer_sk
)
SELECT 
    cs.first_name,
    cs.last_name,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ds.dependent_status,
    ss.total_spend,
    ss.max_store_transactions,
    ss.max_web_transactions
FROM 
    CustomerSales cs
JOIN 
    Demographics ds ON cs.c_customer_sk = ds.cd_demo_sk
JOIN 
    SalesSummary ss ON cs.c_customer_sk = ss.c_customer_sk
WHERE 
    (ss.total_spend IS NOT NULL AND ss.total_spend > 500) 
    OR (ds.cd_gender = 'F' AND ss.max_web_transactions > 5)
ORDER BY 
    ss.total_spend DESC NULLS LAST
LIMIT 50;

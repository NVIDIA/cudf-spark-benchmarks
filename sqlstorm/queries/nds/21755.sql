
WITH RecursiveCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_purchase,
        (SELECT COUNT(*) 
         FROM customer
         WHERE c_birth_year = EXTRACT(YEAR FROM CURRENT_DATE) - (2023 - (SELECT MAX(d_year) FROM date_dim)) 
         AND c_current_cdemo_sk = cd.cd_demo_sk) AS younger_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        c.c_customer_sk
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    rcte.c_first_name,
    rcte.c_last_name,
    rcte.cd_gender,
    CASE 
        WHEN rcte.rank_purchase = 1 THEN 'Top Buyer'
        ELSE 'Regular Buyer'
    END AS buyer_category,
    COALESCE(a.total_sales, 0) AS total_sales,
    rcte.younger_count
FROM 
    RecursiveCTE AS rcte
LEFT JOIN 
    AggregatedSales AS a ON rcte.c_customer_sk = a.c_customer_sk
WHERE 
    rcte.rank_purchase <= 10 
    AND rcte.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC 
LIMIT 5;

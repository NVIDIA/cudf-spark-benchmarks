
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) + COALESCE(SUM(cs.cs_net_paid), 0) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        row_number() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase_estimate
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate > 1000
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_sales,
        d.cd_gender,
        d.cd_marital_status
    FROM customer_sales cs
    INNER JOIN demographics d ON cs.c_customer_sk = d.cd_demo_sk
    WHERE d.rank_by_purchase_estimate <= 10
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    COALESCE(s.total_web_sales, 0) AS web_sales,
    COALESCE(s.total_catalog_sales, 0) AS catalog_sales,
    COALESCE(s.total_sales, 0) AS overall_sales,
    CASE
        WHEN s.total_sales > 5000 THEN 'High Value'
        WHEN s.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM sales_summary s
ORDER BY overall_sales DESC
LIMIT 100;

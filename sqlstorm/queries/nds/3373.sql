
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS orders_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 1000
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.orders_count,
        cs.last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.rank_sales <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.orders_count,
    tc.last_purchase_date,
    COALESCE(NULLIF(tc.cd_gender, ''), 'Not Specified') AS gender,
    COALESCE(NULLIF(tc.cd_marital_status, 'U'), 'Unknown') AS marital_status,
    tc.cd_purchase_estimate,
    CASE 
        WHEN tc.cd_purchase_estimate < 500 THEN 'Low'
        WHEN tc.cd_purchase_estimate BETWEEN 500 AND 1500 THEN 'Medium'
        ELSE 'High'
    END AS purchase_category
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;

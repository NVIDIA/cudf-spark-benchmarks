
WITH  customer_sales_cte AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_sales_cte cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.order_rank <= 10
)
SELECT 
    coalesce(tc.c_customer_sk, 0) AS customer_sk,
    coalesce(tc.total_sales, 0.00) AS total_sales,
    coalesce(tc.total_orders, 0) AS total_orders,
    coalesce(cd.customer_count, 0) AS associated_customer_count,
    coalesce(cd.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    CASE 
        WHEN tc.cd_gender = 'F' THEN 'Female'
        WHEN tc.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender_category
FROM 
    top_customers tc
FULL OUTER JOIN 
    customer_demographics_summary cd ON cd.cd_demo_sk = tc.c_customer_sk
ORDER BY 
    total_sales DESC;

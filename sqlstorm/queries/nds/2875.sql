
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_customers AS (
    SELECT *
    FROM customer_summary
    WHERE purchase_rank <= 5
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_sales AS (
    SELECT 
        cs.c_customer_sk,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
        COALESCE(ws.total_spent, 0) AS total_web_sales
    FROM 
        customer_summary cs
    LEFT JOIN 
        store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        sales_summary ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cs.c_customer_sk, ws.total_spent
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.total_store_sales,
    cs.total_web_sales,
    (COALESCE(cs.total_store_sales, 0) + COALESCE(cs.total_web_sales, 0)) AS total_combined_sales,
    CASE 
        WHEN cs.total_store_sales > cs.total_web_sales THEN 'Store Sales Greater'
        WHEN cs.total_store_sales < cs.total_web_sales THEN 'Web Sales Greater'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM 
    top_customers c
LEFT JOIN 
    customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
ORDER BY 
    total_combined_sales DESC;


WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
customer_sales AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        ss.total_sales,
        ss.order_count,
        ss.avg_order_value
    FROM 
        ranked_customers rc
    LEFT JOIN 
        sales_summary ss ON rc.c_customer_sk = ss.ws_ship_customer_sk
    WHERE 
        rc.gender_rank <= 5
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        CASE WHEN cs.avg_order_value IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status
    FROM 
        customer c
    LEFT JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk 
    WHERE 
        cs.total_sales > 1000 OR cs.avg_order_value > 100
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(cs.avg_order_value, 0) AS avg_order_value,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales >= 5000 THEN 'VIP'
        ELSE 'Regular'
    END AS customer_status,
    NULLIF(c.c_birth_month, 0) AS birth_month,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns
FROM 
    customer c
LEFT JOIN 
    customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cs.total_sales, 
    cs.order_count, 
    cs.avg_order_value, 
    c.c_birth_month
ORDER BY 
    total_sales DESC, 
    customer_status;

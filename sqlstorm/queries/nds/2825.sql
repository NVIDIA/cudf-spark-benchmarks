
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_returns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
customer_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        COALESCE(cr.total_return_amount, 0) AS total_returns,
        cs.order_count,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        RANK() OVER (PARTITION BY ci.ca_state ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    LEFT JOIN 
        customer_returns cr ON cs.c_customer_sk = cr.cr_returning_customer_sk
    JOIN 
        customer_info ci ON cs.c_customer_sk = ci.cd_demo_sk
)
SELECT 
    s.ca_state,
    COUNT(*) AS active_customers,
    SUM(s.total_web_sales) AS total_sales,
    SUM(s.total_returns) AS total_returns,
    AVG(s.total_web_sales) AS avg_sales_per_customer,
    AVG(CASE WHEN s.order_count > 0 THEN s.total_web_sales / NULLIF(s.order_count, 0) ELSE 0 END) AS avg_sales_per_order
FROM 
    sales_summary s
WHERE 
    s.sales_rank <= 10 
    AND s.total_web_sales IS NOT NULL
GROUP BY 
    s.ca_state
ORDER BY 
    total_sales DESC;

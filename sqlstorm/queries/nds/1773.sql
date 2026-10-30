
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid) AS total_web_revenue,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
store_sales_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
        SUM(ss.ss_net_paid) AS total_store_revenue
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
combined_sales AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_orders, 0) AS web_orders,
        COALESCE(cs.total_web_revenue, 0) AS web_revenue,
        COALESCE(ss.total_store_orders, 0) AS store_orders,
        COALESCE(ss.total_store_revenue, 0) AS store_revenue
    FROM 
        customer_sales cs
    FULL OUTER JOIN 
        store_sales_summary ss ON cs.c_customer_id = ss.c_customer_id
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.web_revenue + cs.store_revenue) AS total_revenue
    FROM 
        combined_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_revenue,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.total_revenue DESC) AS revenue_rank
FROM 
    customer_demographics cd
WHERE 
    cd.total_revenue > (
        SELECT AVG(total_revenue) FROM customer_demographics
    )
ORDER BY 
    cd.cd_gender, cd.total_revenue DESC
LIMIT 10;

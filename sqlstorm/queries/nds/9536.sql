
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        AVG(ws.ws_list_price) AS avg_list_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
demographic_analysis AS (
    SELECT 
        gender,
        COUNT(*) AS num_customers,
        SUM(total_spent) AS total_revenue,
        AVG(total_spent) AS avg_spent_per_customer
    FROM (
        SELECT 
            cs.cd_gender AS gender,
            cs.total_spent
        FROM 
            customer_stats cs
        WHERE 
            cs.num_orders > 0
    ) AS gender_stats
    GROUP BY 
        gender
)
SELECT 
    sd.total_sold,
    sd.total_revenue,
    sd.avg_list_price,
    da.num_customers,
    da.total_revenue AS revenue_by_gender,
    da.avg_spent_per_customer
FROM 
    sales_data sd
JOIN 
    demographic_analysis da ON sd.ws_item_sk = (
        SELECT ws.ws_item_sk 
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c)
        LIMIT 1
    )
ORDER BY 
    sd.total_revenue DESC
LIMIT 10 OFFSET 0;

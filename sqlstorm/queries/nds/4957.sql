
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_country,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
recent_sales AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_date >= CURRENT_DATE - INTERVAL '6 months'
        )
    GROUP BY 
        ws.ws_ship_customer_sk
),
sales_analysis AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        COALESCE(rs.total_profit, 0) AS total_profit,
        COALESCE(rs.total_orders, 0) AS total_orders,
        cd.purchase_rank
    FROM 
        customer_details cd
        LEFT JOIN recent_sales rs ON cd.c_customer_sk = rs.ws_ship_customer_sk
)

SELECT 
    sa.c_first_name,
    sa.c_last_name,
    sa.total_profit,
    sa.total_orders,
    (sa.total_profit / NULLIF(sa.total_orders, 0)) AS avg_profit_per_order,
    CASE 
        WHEN sa.total_profit > 1000 THEN 'High Value Customer'
        WHEN sa.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    sales_analysis sa
WHERE 
    sa.purchase_rank <= 10
ORDER BY 
    sa.total_profit DESC
LIMIT 50;

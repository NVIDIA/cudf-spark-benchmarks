
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2000001 AND 2005000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_purchase_estimate > 1000
),
sales_summary AS (
    SELECT 
        ci.ca_city,
        ci.ca_state,
        SUM(rs.ws_net_paid) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders
    FROM 
        ranked_sales rs
    JOIN 
        customer_info ci ON rs.ws_item_sk = ci.c_customer_sk
    WHERE 
        rs.rank = 1
    GROUP BY 
        ci.ca_city, ci.ca_state
)
SELECT 
    ss.ca_city,
    ss.ca_state,
    ss.total_sales,
    ss.total_orders,
    CASE 
        WHEN ss.total_orders > 50 THEN 'High Volume'
        WHEN ss.total_orders BETWEEN 20 AND 50 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS order_volume_label
FROM 
    sales_summary ss
WHERE 
    ss.total_sales IS NOT NULL
ORDER BY 
    ss.total_sales DESC
LIMIT 10;

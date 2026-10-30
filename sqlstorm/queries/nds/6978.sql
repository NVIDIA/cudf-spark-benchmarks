WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN 2451545 AND 2451546 
    GROUP BY 
        ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS orders,
        AVG(CASE 
            WHEN cd_gender = 'M' THEN cd_purchase_estimate 
            ELSE 0 END) AS avg_purchase_male,
        AVG(CASE 
            WHEN cd_gender = 'F' THEN cd_purchase_estimate 
            ELSE 0 END) AS avg_purchase_female
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(rs.total_sales) AS total_sales_amount,
    AVG(cs.orders) AS avg_orders_per_customer,
    MAX(cs.avg_purchase_male) AS max_avg_purchase_male,
    MAX(cs.avg_purchase_female) AS max_avg_purchase_female
FROM 
    customer_address ca
JOIN 
    ranked_sales rs ON rs.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
JOIN 
    customer_stats cs ON cs.c_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(rs.total_sales) > 100000
ORDER BY 
    total_sales_amount DESC;
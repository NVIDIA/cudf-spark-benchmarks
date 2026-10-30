
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20.00
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_ext_sales_price) AS total_sales
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        top_sales ts ON ws.ws_item_sk = ts.ws_item_sk
    GROUP BY 
        c.c_customer_sk 
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    a.total_orders,
    a.total_profit
FROM 
    customer_analysis a
JOIN 
    customer c ON a.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    a.total_profit > 1000
ORDER BY 
    a.total_profit DESC
LIMIT 10;

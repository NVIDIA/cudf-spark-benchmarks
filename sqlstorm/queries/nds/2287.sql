
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_paid
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_item_sk
    WHERE 
        c.c_birth_year > 1980 AND
        ca.ca_state IN ('CA', 'NY')
)
SELECT 
    ti.ca_city,
    ti.ca_state,
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_paid
FROM 
    top_items ti
WHERE 
    ti.total_quantity > (SELECT AVG(total_quantity) FROM top_items)
ORDER BY 
    ti.total_net_paid DESC
LIMIT 10;

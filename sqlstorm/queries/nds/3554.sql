
WITH sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (ORDER BY i.i_current_price DESC) AS price_rank
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_paid,
        id.i_item_desc,
        id.i_current_price
    FROM 
        sales_summary ss
    JOIN 
        item_details id ON ss.ws_item_sk = id.i_item_sk
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_net_paid,
    ts.i_current_price,
    COALESCE(NULLIF(ts.total_net_paid - (ts.total_net_paid * 0.1), 0), 0) AS adjusted_net_paid,
    (SELECT 
         AVG(total_net_paid) 
     FROM 
         top_sales
     WHERE 
         i_current_price < ts.i_current_price) AS avg_lower_price_net_paid
FROM 
    top_sales ts
LEFT JOIN 
    customer_address ca ON ts.ws_item_sk = ca.ca_address_sk
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    c.c_customer_id IS NOT NULL 
    AND ts.total_quantity > 100
ORDER BY 
    ts.total_net_paid DESC
LIMIT 100;

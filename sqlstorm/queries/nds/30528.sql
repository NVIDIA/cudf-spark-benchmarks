
WITH  sales_summary AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_order_number, ws_item_sk
),
latest_sales AS (
    SELECT 
        s.ws_order_number,
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales
    FROM 
        sales_summary s
    JOIN (
        SELECT 
            ws_item_sk,
            MAX(ws_order_number) AS max_order
        FROM 
            sales_summary
        GROUP BY 
            ws_item_sk
    ) max_orders ON s.ws_item_sk = max_orders.ws_item_sk 
            AND s.ws_order_number = max_orders.max_order
)
SELECT 
    COALESCE(c.c_birth_country, 'Unknown') AS customer_country,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    AVG(ws.ws_net_paid) AS avg_order_value,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS product_names,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    latest_sales ls ON ws.ws_order_number = ls.ws_order_number
JOIN 
    item i ON ls.ws_item_sk = i.i_item_sk
WHERE 
    (c.c_birth_year >= 1970 OR c.c_birth_country = 'USA')
    AND (ws.ws_net_paid > 0 OR (ws.ws_net_paid IS NULL AND ws.ws_net_paid_inc_tax > 0))
GROUP BY 
    customer_country
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;

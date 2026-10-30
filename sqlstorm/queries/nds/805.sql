
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-31')
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_paid,
        ss.order_count
    FROM 
        sales_summary ss
    WHERE 
        ss.rn <= 10
),
returned_items AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amount) AS total_returned
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-31')
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_paid,
    ti.order_count,
    COALESCE(ri.return_count, 0) AS return_count,
    COALESCE(ri.total_returned, 0) AS total_returned,
    (ti.total_net_paid - COALESCE(ri.total_returned, 0)) AS net_profit_adjusted
FROM 
    top_items ti
LEFT JOIN 
    returned_items ri ON ti.ws_item_sk = ri.cr_item_sk
ORDER BY 
    net_profit_adjusted DESC
LIMIT 20;

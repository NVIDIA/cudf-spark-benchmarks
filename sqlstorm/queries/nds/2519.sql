
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE rn <= 5)
    GROUP BY 
        ws_item_sk
),
customer_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.total_sales, 0) AS total_sales_amount,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(ss.total_quantity, 0) > 0 
        THEN (COALESCE(ss.total_sales, 0) - COALESCE(cr.total_return_amount, 0)) / COALESCE(ss.total_quantity, 1)
        ELSE NULL 
    END AS net_sales_per_unit
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    customer_returns cr ON i.i_item_sk = cr.sr_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
    AND i.i_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_date_sk IS NOT NULL)
ORDER BY 
    net_sales_per_unit DESC
LIMIT 10;

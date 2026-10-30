
WITH processed_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        CONCAT('Item ID: ', ws_item_sk, ' | Total Quantity: ', SUM(ws_quantity), ' | Total Net Paid: ', SUM(ws_net_paid)) AS sales_info
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY ws_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        SUBSTRING(i_item_desc, 1, 20) AS short_desc
    FROM item
)
SELECT 
    ps.sales_info,
    id.i_item_desc,
    id.i_current_price
FROM processed_sales ps
JOIN item_details id ON ps.ws_item_sk = id.i_item_sk
ORDER BY ps.total_net_paid DESC
LIMIT 10;

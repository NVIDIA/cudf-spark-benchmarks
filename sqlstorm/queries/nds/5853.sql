
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_profit,
        i.i_item_desc,
        i.i_brand,
        i.i_product_name
    FROM sales_data sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    ORDER BY sd.total_sales DESC
    LIMIT 10
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales,
    t.avg_profit,
    i.i_item_desc,
    i.i_brand,
    i.i_product_name,
    COALESCE(AVG(CASE WHEN wr_returned_date_sk IS NOT NULL THEN wr_return_amt END), 0) AS avg_return_amount,
    COALESCE(AVG(CASE WHEN cr_returned_date_sk IS NOT NULL THEN cr_return_amount END), 0) AS avg_catalog_return_amount
FROM top_sales t
LEFT JOIN web_returns wr ON t.ws_item_sk = wr.wr_item_sk
LEFT JOIN catalog_returns cr ON t.ws_item_sk = cr.cr_item_sk
JOIN item i ON t.ws_item_sk = i.i_item_sk
GROUP BY 
    t.ws_item_sk, 
    t.total_quantity, 
    t.total_sales, 
    t.avg_profit, 
    i.i_item_desc, 
    i.i_brand, 
    i.i_product_name
ORDER BY t.total_sales DESC;

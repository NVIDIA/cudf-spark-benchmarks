
WITH  top_return_items AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) > 100
), 
popular_items AS (
    SELECT ws_item_sk, COUNT(ws_order_number) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING COUNT(ws_order_number) > 50
), 
item_details AS (
    SELECT i.i_item_sk, i.i_product_name, i.i_current_price,
           COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown') AS customer_name,
           ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY i.i_current_price DESC) AS price_rank
    FROM item i
    LEFT JOIN customer c ON i.i_item_sk = c.c_current_hdemo_sk
)
SELECT id.i_product_name, 
       id.i_current_price, 
       COALESCE(r.total_returned, 0) AS total_returned,
       COALESCE(s.total_sales, 0) AS total_sales,
       CASE WHEN r.total_returned IS NULL THEN 'No Returns'
            WHEN s.total_sales IS NULL THEN 'No Sales'
            ELSE 'Returns & Sales' END AS sales_status
FROM item_details id
LEFT JOIN top_return_items r ON id.i_item_sk = r.sr_item_sk
LEFT JOIN popular_items s ON id.i_item_sk = s.ws_item_sk
WHERE id.price_rank = 1
ORDER BY id.i_current_price DESC
LIMIT 10;


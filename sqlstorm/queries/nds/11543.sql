
WITH top_items AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT i.i_item_id, i.i_item_desc, ti.total_sales
FROM item i
JOIN top_items ti ON i.i_item_sk = ti.ws_item_sk;


WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
), 
top_sales AS (
    SELECT 
        ws_item_sk,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(ws_order_number) AS order_count
    FROM ranked_sales
    WHERE sales_rank <= 10
    GROUP BY ws_item_sk
)
SELECT 
    i_item_id,
    i_item_desc,
    avg_sales_price,
    order_count,
    ca_city,
    ca_state
FROM top_sales
JOIN item ON top_sales.ws_item_sk = item.i_item_sk
JOIN customer_address ca ON item.i_item_sk = ca.ca_address_sk
WHERE ca_state IN ('CA', 'TX', 'NY')
ORDER BY avg_sales_price DESC
LIMIT 50;

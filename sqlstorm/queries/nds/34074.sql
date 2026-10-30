
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
),
item_ranks AS (
    SELECT 
        i_item_sk, 
        i_item_id, 
        i_product_name, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM (
        SELECT ws_item_sk, ws_quantity, ws_sales_price 
        FROM web_sales
        UNION ALL
        SELECT cs_item_sk, cs_quantity, cs_sales_price 
        FROM catalog_sales
        UNION ALL
        SELECT ss_item_sk, ss_quantity, ss_sales_price 
        FROM store_sales
    ) AS combined_sales
    JOIN item ON item.i_item_sk = combined_sales.ws_item_sk
    GROUP BY i_item_sk, i_item_id, i_product_name
),
top_items AS (
    SELECT *, 
           CASE 
               WHEN total_quantity IS NULL THEN 'No Sales'
               WHEN total_quantity < 10 THEN 'Low Sales'
               ELSE 'High Sales'
           END AS sales_category
    FROM item_ranks
    WHERE sales_rank <= 10
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    ti.i_item_id, 
    ti.i_product_name, 
    ti.total_quantity, 
    ti.total_sales_price, 
    ti.sales_category
FROM top_items ti
LEFT JOIN customer c ON c.c_current_cdemo_sk IS NOT NULL
LEFT JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE ca.ca_city IS NOT NULL
ORDER BY ti.total_sales_price DESC;

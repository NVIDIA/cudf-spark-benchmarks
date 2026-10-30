
WITH  sales_hierarchy AS (
    SELECT 
        ws_order_number,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) as rn
    FROM web_sales
    UNION ALL
    SELECT 
        cs_order_number,
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_sales_price DESC) as rn
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales)
)
SELECT 
    sh.ws_order_number,
    SUM(sh.ws_quantity) AS total_quantity,
    SUM(sh.ws_sales_price * sh.ws_quantity) AS total_sales,
    COUNT(DISTINCT sh.ws_item_sk) AS distinct_items_sold,
    CASE 
        WHEN COUNT(DISTINCT sh.ws_item_sk) > 5 THEN 'High Volume'
        WHEN COUNT(DISTINCT sh.ws_item_sk) BETWEEN 3 AND 5 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM sales_hierarchy sh
JOIN customer_demographics cd ON sh.ws_order_number = cd.cd_demo_sk
LEFT JOIN customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
WHERE ca.ca_state IS NOT NULL 
AND sh.ws_sales_price > 0
GROUP BY sh.ws_order_number
HAVING SUM(sh.ws_quantity) > 10
ORDER BY total_sales DESC
LIMIT 10;


WITH ranked_items AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        i.i_category, 
        COUNT(ws.ws_order_number) AS sales_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE i.i_item_desc IS NOT NULL
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_brand, i.i_category
),
keyword_search AS (
    SELECT 
        item.i_item_sk, 
        item.i_item_desc, 
        item.i_brand,
        item.i_category,
        ranked_items.sales_count,
        ranked_items.total_sales,
        ROW_NUMBER() OVER (PARTITION BY item.i_category ORDER BY ranked_items.total_sales DESC) AS ranking
    FROM item
    JOIN ranked_items ON item.i_item_sk = ranked_items.i_item_sk
    WHERE LOWER(item.i_item_desc) LIKE '%organic%' OR LOWER(item.i_item_desc) LIKE '%eco%'
)
SELECT 
    keyword_search.i_item_sk, 
    keyword_search.i_item_desc, 
    keyword_search.i_brand, 
    keyword_search.i_category, 
    keyword_search.sales_count,
    keyword_search.total_sales,
    keyword_search.ranking
FROM keyword_search
WHERE keyword_search.ranking <= 10
ORDER BY keyword_search.i_category, keyword_search.total_sales DESC;

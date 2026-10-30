
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
)
SELECT 
    id.i_item_desc,
    id.i_brand,
    id.i_current_price,
    COALESCE(rs.total_sales, 0) AS total_sales,
    rs.sales_rank
FROM 
    item_details id
LEFT JOIN 
    ranked_sales rs ON id.i_item_sk = rs.ws_item_sk
WHERE 
    (COALESCE(rs.sales_rank, 0) <= 10 OR rs.total_sales IS NULL)
    AND id.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_current_price IS NOT NULL)
ORDER BY 
    total_sales DESC NULLS LAST;

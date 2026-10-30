
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 100 
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        COALESCE(i.i_item_desc, 'Unknown Item') AS item_desc,
        ROW_NUMBER() OVER (ORDER BY r.total_sales DESC) AS overall_rank
    FROM 
        ranked_sales r
    LEFT JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 5
),
zero_sales AS (
    SELECT 
        i.i_item_sk AS ws_item_sk,
        0 AS total_sales,
        'No Sales Data' AS item_desc
    FROM 
        item i
    WHERE 
        i.i_item_sk NOT IN (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk BETWEEN 1 AND 100)
)
SELECT 
    COALESCE(ts.ws_item_sk, zs.ws_item_sk) AS item_sk,
    COALESCE(ts.total_sales, zs.total_sales) AS total_sales,
    COALESCE(ts.item_desc, zs.item_desc) AS item_desc
FROM 
    top_sales ts
FULL OUTER JOIN 
    zero_sales zs ON ts.ws_item_sk = zs.ws_item_sk
ORDER BY 
    total_sales DESC
LIMIT 10;

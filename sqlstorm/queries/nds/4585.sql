
WITH recent_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
high_sales AS (
    SELECT 
        rws.ws_item_sk,
        rws.total_quantity,
        rws.total_sales,
        ROW_NUMBER() OVER (ORDER BY rws.total_sales DESC) AS sales_rank
    FROM 
        recent_sales rws
    WHERE 
        rws.total_sales > 1000
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    hs.total_quantity,
    hs.total_sales,
    COALESCE(CAST(ROUND((hs.total_sales / NULLIF(hs.total_quantity, 0)), 2) AS DECIMAL(10,2)), 0) AS avg_sales_price,
    CASE 
        WHEN hs.total_quantity IS NULL THEN 'No Sales'
        WHEN hs.total_sales = 0 THEN 'No Revenue'
        ELSE 'Active Sales'
    END AS sales_status
FROM 
    high_sales hs
JOIN 
    item i ON hs.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND (i.i_current_price * hs.total_quantity) >= 500
ORDER BY 
    hs.total_sales DESC
LIMIT 10;

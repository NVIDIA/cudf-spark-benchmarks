
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        COALESCE(NULLIF(ws.ws_ext_discount_amt, 0), 0.01) AS effective_discount
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
sell_data AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_sales_price) AS total_sales,
        AVG(r.ws_sales_price) AS avg_sales,
        COUNT(DISTINCT r.ws_sold_date_sk) AS days_sold
    FROM
        ranked_sales r
    WHERE 
        r.sales_rank <= 10
    GROUP BY 
        r.ws_item_sk
),
low_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.avg_sales,
        CASE 
            WHEN sd.total_sales < 1000 THEN 'Low'
            WHEN sd.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS sales_band
    FROM 
        sell_data sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ls.total_sales, 0) AS total_sales,
    COALESCE(ls.avg_sales, 0) AS avg_sales,
    ls.sales_band,
    DENSE_RANK() OVER (ORDER BY COALESCE(ls.total_sales, 0) DESC) AS sales_rank,
    COUNT(*) OVER () AS total_items
FROM 
    item i
LEFT JOIN 
    low_sales ls ON i.i_item_sk = ls.ws_item_sk
WHERE 
    (ls.total_sales IS NULL OR ls.avg_sales > 50)
    AND i.i_current_price IS NOT NULL
ORDER BY 
    ls.total_sales DESC, i.i_item_id
LIMIT 10 OFFSET 5;

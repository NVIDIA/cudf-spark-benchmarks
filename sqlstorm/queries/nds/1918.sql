
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
SalesWithRank AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(swr.total_quantity, 0) AS total_quantity,
    COALESCE(swr.total_sales, 0.00) AS total_sales,
    swr.order_count,
    CASE 
        WHEN swr.sales_rank IS NOT NULL THEN swr.sales_rank 
        ELSE (SELECT MAX(sales_rank) + 1 FROM SalesWithRank) 
    END AS sales_rank
FROM 
    item i
LEFT JOIN 
    SalesWithRank swr ON i.i_item_sk = swr.ws_item_sk
WHERE 
    i.i_current_price > 20.00
    AND i.i_item_desc IS NOT NULL
ORDER BY 
    swr.total_sales DESC NULLS LAST, 
    swr.total_quantity DESC NULLS LAST
LIMIT 100;


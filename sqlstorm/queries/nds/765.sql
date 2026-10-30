
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450050
),
HighValueSales AS (
    SELECT 
        hs.ws_item_sk,
        SUM(hs.ws_sales_price) AS total_sales
    FROM 
        RankedSales hs
    WHERE 
        hs.rn <= 5
    GROUP BY 
        hs.ws_item_sk
),
HighestSales AS (
    SELECT 
        hvs.ws_item_sk,
        hvs.total_sales,
        RANK() OVER (ORDER BY hvs.total_sales DESC) AS sales_rank
    FROM 
        HighValueSales hvs
)
SELECT 
    i.i_item_id,
    COALESCE(m.ms_order_count, 0) AS max_order_count,
    COALESCE(sales.total_sales, 0) AS total_sales,
    i.i_current_price,
    CONCAT('Item: ', i.i_item_desc, ', Total Sales: ', COALESCE(sales.total_sales, 0)) AS sales_info
FROM 
    item i
LEFT JOIN (
    SELECT 
        ws_item_sk, 
        COUNT(ws_order_number) AS ms_order_count 
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
) m ON i.i_item_sk = m.ws_item_sk
LEFT JOIN HighestSales sales ON i.i_item_sk = sales.ws_item_sk
WHERE 
    sales.sales_rank = 1 OR sales.sales_rank IS NULL
ORDER BY 
    total_sales DESC
LIMIT 10;

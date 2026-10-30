
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank,
        SUM(ws_sales_price * ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_revenue
    FROM 
        web_sales
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_category,
        COALESCE(i_current_price, 0) AS current_price
    FROM 
        item
)
SELECT 
    id.i_item_desc,
    id.i_category,
    SUM(rs.ws_quantity) AS total_units_sold,
    ROUND(SUM(rs.ws_sales_price * rs.ws_quantity), 2) AS total_sales,
    id.current_price,
    ROUND(AVG(CASE WHEN rs.sales_rank = 1 THEN rs.ws_sales_price ELSE NULL END), 2) AS avg_top_price,
    COUNT(DISTINCT CASE WHEN rs.sales_rank = 1 AND rs.ws_sales_price > id.current_price THEN rs.ws_item_sk END) AS price_increases
FROM 
    RankedSales rs
LEFT JOIN 
    ItemDetails id ON rs.ws_item_sk = id.i_item_sk
WHERE 
    rs.sales_rank <= 5
GROUP BY 
    id.i_item_desc, id.i_category, id.current_price
HAVING 
    SUM(rs.ws_quantity) > 100
ORDER BY 
    total_sales DESC;

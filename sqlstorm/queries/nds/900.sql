
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), ItemAnalysis AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(rs.total_quantity, 0) AS total_quantity_sold,
        COALESCE(rs.total_sales, 0) AS total_sales_amount,
        CASE 
            WHEN rs.total_quantity IS NULL THEN 'No sales'
            WHEN rs.total_quantity < 10 THEN 'Low sales'
            ELSE 'High sales'
        END AS sales_level,
        i.i_item_sk  -- Added to GROUP BY in the main query
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
)
SELECT 
    ia.i_item_id,
    ia.i_item_desc,
    ia.total_quantity_sold,
    ia.total_sales_amount,
    ia.sales_level,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
    AVG(cs.cs_sales_price) AS avg_catalog_price,
    MAX(CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_sales_price ELSE NULL END) AS max_catalog_price,
    MIN(CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_sales_price ELSE NULL END) AS min_catalog_price
FROM 
    ItemAnalysis ia
LEFT JOIN 
    catalog_sales cs ON ia.i_item_sk = cs.cs_item_sk
GROUP BY 
    ia.i_item_id, ia.i_item_desc, ia.total_quantity_sold, ia.total_sales_amount, ia.sales_level, ia.i_item_sk
HAVING 
    ia.total_sales_amount > 1000
ORDER BY 
    ia.total_sales_amount DESC
LIMIT 10;

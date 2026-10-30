WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000)
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
    INNER JOIN 
        (SELECT DISTINCT g.ws_item_sk FROM web_sales g WHERE g.ws_ship_date_sk IS NOT NULL) AS shipped_items
    ON 
        i.i_item_sk = shipped_items.ws_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    COALESCE(rs.total_sales, 0) AS total_sales,
    id.i_current_price,
    id.i_brand,
    id.i_category,
    CASE 
        WHEN rc.shipping_count IS NULL THEN 'Not Shipped'
        ELSE 'Shipped'
    END AS shipping_status,
    EXTRACT(YEAR FROM cast('2002-10-01' as date)) - (SELECT MIN(d_year) FROM date_dim WHERE d_date_sk IN 
        (SELECT DISTINCT ws_sold_date_sk FROM web_sales)) AS age_of_first_sale
FROM 
    ItemDetails id
LEFT JOIN 
    (SELECT 
        ws_item_sk, 
        COUNT(ws_ship_date_sk) AS shipping_count 
     FROM 
        web_sales 
     GROUP BY ws_item_sk) rc 
ON 
    id.i_item_sk = rc.ws_item_sk
LEFT JOIN 
    RankedSales rs 
ON 
    id.i_item_sk = rs.ws_item_sk 
WHERE 
    (id.i_current_price - COALESCE(rs.total_sales, 0)) > 0
ORDER BY 
    id.i_category, 
    total_sales DESC
LIMIT 10 OFFSET 5;
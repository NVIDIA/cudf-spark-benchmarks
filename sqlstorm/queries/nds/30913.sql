
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_sales_price) AS total_sales 
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
    GROUP BY 
        cs_item_sk
),
Combined_Sales AS (
    SELECT 
        item.i_item_id,
        COALESCE(SUM(sc.total_quantity), 0) AS total_web_quantity,
        COALESCE(MAX(sc.total_sales), 0) AS total_web_sales,
        COALESCE(SUM(cs.total_quantity), 0) AS total_catalog_quantity,
        COALESCE(MAX(cs.total_sales), 0) AS total_catalog_sales
    FROM 
        item
    LEFT JOIN 
        Sales_CTE sc ON item.i_item_sk = sc.ws_item_sk
    LEFT JOIN 
        (
            SELECT 
                cs_item_sk, 
                SUM(cs_quantity) AS total_quantity,
                SUM(cs_sales_price) AS total_sales
            FROM 
                catalog_sales 
            GROUP BY 
                cs_item_sk
        ) cs ON item.i_item_sk = cs.cs_item_sk
    GROUP BY 
        item.i_item_id
),
Sales_Stats AS (
    SELECT 
        cs.*, 
        cs.total_web_sales - cs.total_web_quantity AS sales_difference,
        ROUND((cs.total_web_sales + cs.total_catalog_sales) / NULLIF((cs.total_web_quantity + cs.total_catalog_quantity), 0), 2) AS avg_price_per_item
    FROM 
        Combined_Sales cs
)
SELECT 
    s.i_item_id AS item_id, 
    s.total_web_quantity, 
    s.total_web_sales, 
    s.total_catalog_quantity, 
    s.total_catalog_sales, 
    s.sales_difference,
    s.avg_price_per_item,
    CASE 
        WHEN s.total_web_sales > s.total_catalog_sales THEN 'Web Sales Dominant'
        WHEN s.total_web_sales < s.total_catalog_sales THEN 'Catalog Sales Dominant'
        ELSE 'Equal Sales'
    END AS sales_dominance
FROM 
    Sales_Stats s
ORDER BY 
    s.avg_price_per_item DESC
LIMIT 100;

WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 10000 
    GROUP BY 
        ws_item_sk
),
total_sales_per_item AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_catalog_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1 AND 10000
    GROUP BY 
        cs_item_sk
),
combined_sales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_sales, 0) AS web_sales_total,
        COALESCE(c.total_catalog_sales, 0) AS catalog_sales_total,
        COALESCE(s.total_sales, 0) + COALESCE(c.total_catalog_sales, 0) AS combined_sales_total
    FROM 
        sales_cte s
    FULL OUTER JOIN 
        total_sales_per_item c ON s.ws_item_sk = c.cs_item_sk
),
high_sales_items AS (
    SELECT 
        *,
        CASE 
            WHEN combined_sales_total > 500 THEN 'High Performer'
            WHEN combined_sales_total BETWEEN 101 AND 500 THEN 'Mid Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM 
        combined_sales
)
SELECT 
    w.w_warehouse_name,
    h.performance_category,
    COUNT(*) AS item_count,
    SUM(h.combined_sales_total) AS total_combined_sales
FROM 
    high_sales_items h
JOIN 
    inventory i ON h.ws_item_sk = i.inv_item_sk
JOIN 
    warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    w.w_country = 'USA' AND
    (h.performance_category = 'High Performer' OR h.performance_category IS NOT NULL)
GROUP BY 
    w.w_warehouse_name, h.performance_category
HAVING 
    SUM(h.combined_sales_total) > (SELECT AVG(combined_sales_total) FROM high_sales_items WHERE performance_category = 'High Performer')
ORDER BY 
    total_combined_sales DESC
LIMIT 10;

WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS cumulative_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS row_num
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_order_number) AS cumulative_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_order_number) AS row_num
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
sales_summary AS (
    SELECT 
        item.i_item_id,
        COALESCE(MAX(rs.ws_ext_sales_price), 0) AS max_sales_price,
        AVG(rs.cumulative_sales) AS avg_cumulative_sales,
        COUNT(DISTINCT rs.ws_order_number) AS order_count,
        SUM(rs.cumulative_sales) AS total_sales
    FROM 
        item
    LEFT JOIN 
        ranked_sales rs ON item.i_item_sk = rs.ws_item_sk
    GROUP BY 
        item.i_item_id
)
SELECT 
    ss.i_item_id,
    ss.max_sales_price,
    ss.avg_cumulative_sales,
    CASE 
        WHEN ss.order_count = 0 THEN NULL
        ELSE ss.total_sales / NULLIF(ss.order_count, 0)
    END AS average_sales_per_order,
    CASE 
        WHEN ss.total_sales > 10000 THEN 'High Sales'
        WHEN ss.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    sales_summary ss
WHERE 
    (ss.max_sales_price IS NULL OR ss.max_sales_price < 100) 
    AND EXISTS (SELECT 1 FROM store s WHERE s.s_number_employees IS NOT NULL)
ORDER BY 
    ss.total_sales DESC;

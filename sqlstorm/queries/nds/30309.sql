WITH RecursiveSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2450117 AND 2450445 
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
        cs_sold_date_sk BETWEEN 2450117 AND 2450445 
    GROUP BY 
        cs_item_sk
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(s.total_quantity, 0) AS total_quantity, 
        COALESCE(s.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(s.total_sales, 0) DESC) AS sales_rank 
    FROM 
        item
    LEFT JOIN (
        SELECT 
            rs.ws_item_sk, 
            SUM(rs.total_quantity) AS total_quantity,
            SUM(rs.total_sales) AS total_sales
        FROM 
            RecursiveSales rs 
        GROUP BY 
            rs.ws_item_sk
    ) s ON item.i_item_sk = s.ws_item_sk 
    WHERE 
        item.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (item.i_rec_end_date IS NULL OR item.i_rec_end_date > cast('2002-10-01' as date))
)

SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Seller'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Seller'
        ELSE 'Low Seller' 
    END AS sales_category 
FROM 
    SalesSummary ss
WHERE 
    ss.total_quantity > 0
ORDER BY 
    ss.sales_rank ASC
LIMIT 10;
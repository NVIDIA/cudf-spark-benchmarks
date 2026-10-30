
WITH RecentSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales_price,
        DENSE_RANK() OVER (ORDER BY rs.total_sales_price DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        RecentSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
),
SalesSummary AS (
    SELECT
        tp.i_item_id,
        tp.i_item_desc,
        tp.total_quantity,
        tp.total_sales_price,
        CASE 
            WHEN tp.sales_rank <= 10 THEN 'Top 10 Products'
            ELSE 'Other Products'
        END AS product_category
    FROM 
        TopProducts tp
)
SELECT 
    ss.product_category,
    COUNT(*) AS product_count,
    AVG(ss.total_sales_price) AS avg_sales_price,
    SUM(ss.total_quantity) AS total_quantity_sold
FROM 
    SalesSummary ss
GROUP BY 
    ss.product_category
UNION ALL
SELECT 
    'Null Products' AS product_category,
    COUNT(*) AS product_count,
    AVG(NULLIF(total_sales_price, 0)) AS avg_sales_price,
    SUM(total_quantity) AS total_quantity_sold
FROM 
    SalesSummary ss
WHERE 
    ss.total_sales_price IS NULL
ORDER BY 
    product_category;

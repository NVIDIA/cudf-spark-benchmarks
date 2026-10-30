WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
),
TotalSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(COALESCE(rs.ws_sales_price, 0)) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
SalesInfo AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ts.total_sales,
        CASE 
            WHEN ts.total_sales > 1000 THEN 'High'
            WHEN ts.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        TotalSales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
)
SELECT 
    s.sales_category,
    COUNT(s.i_item_id) AS item_count,
    AVG(s.total_sales) AS avg_sales
FROM 
    SalesInfo s
GROUP BY 
    s.sales_category
ORDER BY 
    s.sales_category;
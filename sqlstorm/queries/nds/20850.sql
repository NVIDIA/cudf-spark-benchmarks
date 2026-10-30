
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim 
            WHERE d_year = (SELECT MAX(d_year) FROM date_dim) 
            AND d_week_seq = (SELECT d_week_seq FROM date_dim WHERE d_date = '2002-10-01')
        )
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_sold_date_sk) AS sale_days
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5 
    GROUP BY 
        rs.ws_item_sk
),
SalesPerc AS (
    SELECT 
        fs.ws_item_sk,
        fs.total_quantity,
        fs.total_sales,
        fs.sale_days,
        ROUND(fs.total_sales / NULLIF(SUM(fs.total_sales) OVER (), 0), 4) AS sales_percentage
    FROM 
        FilteredSales fs
)
SELECT 
    i.i_item_id,
    COALESCE(sp.total_quantity, 0) AS total_quantity,
    COALESCE(sp.total_sales, 0) AS total_sales,
    COALESCE(sp.sale_days, 0) AS sale_days,
    COALESCE(sp.sales_percentage, 0) AS sales_percentage,
    CASE 
        WHEN i.i_current_price > 0 THEN ROUND((COALESCE(sp.total_sales, 0) / NULLIF(COUNT(sp.ws_item_sk) OVER (PARTITION BY i.i_item_id), 0)), 2)
        ELSE NULL
    END AS avg_sales_per_unit
FROM 
    item i
LEFT JOIN 
    SalesPerc sp ON i.i_item_sk = sp.ws_item_sk
WHERE 
    i.i_current_price IS NOT NULL 
    AND (i.i_current_price > 0 OR sp.total_sales IS NOT NULL)
ORDER BY 
    sales_percentage DESC, total_sales DESC
LIMIT 10;

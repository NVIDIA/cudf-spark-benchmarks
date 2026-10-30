
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        SUM(cs_quantity),
        SUM(cs_ext_sales_price)
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_item_sk
),
RankedSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        RANK() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM item
    LEFT JOIN (
        SELECT 
            ws_item_sk AS item_sk,
            SUM(total_quantity) AS total_quantity,
            SUM(total_sales) AS total_sales
        FROM SalesData
        GROUP BY ws_item_sk
    ) sd ON item.i_item_sk = sd.item_sk
),
SalesSummary AS (
    SELECT 
        rs.i_item_id,
        rs.i_item_desc,
        rs.total_quantity,
        rs.total_sales,
        rs.sales_rank,
        CASE 
            WHEN rs.sales_rank <= 10 THEN 'Top Seller'
            WHEN rs.sales_rank <= 50 THEN 'Average Seller'
            ELSE 'Underperformer'
        END AS performance_category
    FROM RankedSales rs
)
SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    ss.performance_category,
    (SELECT AVG(total_sales) FROM SalesSummary) AS avg_sales,
    (SELECT COUNT(DISTINCT ws_item_sk) FROM web_sales WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_holiday = 'Y')) AS holiday_sold_items
FROM SalesSummary ss
WHERE ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
ORDER BY ss.total_sales DESC
LIMIT 20;

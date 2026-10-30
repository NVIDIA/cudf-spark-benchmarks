
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS PriceRank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
), HighValueSales AS (
    SELECT 
        item.i_item_id,
        SUM(rs.ws_sales_price) AS TotalSales,
        COUNT(DISTINCT rs.ws_order_number) AS UniqueOrders
    FROM 
        RankedSales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.PriceRank <= 5
    GROUP BY 
        item.i_item_id
), RecentSales AS (
    SELECT 
        ws_item_sk,
        MAX(ws_sold_date_sk) AS LastSoldDate,
        SUM(ws_sales_price) AS TotalRecentSales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = DATE '2002-10-01' - INTERVAL '30 days')
    GROUP BY 
        ws_item_sk
), SalesSummary AS (
    SELECT 
        hi.i_item_id,
        COALESCE(rv.TotalSales, 0) AS TotalSales,
        COALESCE(rv.UniqueOrders, 0) AS UniqueOrders,
        COALESCE(rs.TotalRecentSales, 0) AS RecentSalesAmount
    FROM 
        item hi
    LEFT JOIN 
        HighValueSales rv ON hi.i_item_id = rv.i_item_id
    LEFT JOIN 
        RecentSales rs ON hi.i_item_sk = rs.ws_item_sk
)
SELECT 
    ss.i_item_id,
    CONCAT('Item ID: ', ss.i_item_id, ' — Total Sales: $', CAST(ss.TotalSales AS DECIMAL(10, 2)), 
           ' — Unique Orders: ', ss.UniqueOrders, 
           ' — Recent Sales (Last 30 days): $', CAST(ss.RecentSalesAmount AS DECIMAL(10, 2))) AS SalesDetails,
    CASE
        WHEN ss.TotalSales > 10000 THEN 'High Performer'
        WHEN ss.TotalSales BETWEEN 5000 AND 10000 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory
FROM 
    SalesSummary ss
WHERE 
    ss.TotalSales IS NOT NULL AND ss.RecentSalesAmount IS NOT NULL
ORDER BY 
    ss.TotalSales DESC
LIMIT 100;

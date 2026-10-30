
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS TotalQuantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20.00
        AND ws.ws_sold_date_sk = (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = 2023
        )
),
AggregatedSales AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(rs.ws_order_number) AS OrderCount,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS TotalRevenue
    FROM RankedSales rs
    WHERE rs.PriceRank <= 5
    GROUP BY rs.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(asales.OrderCount, 0) AS OrderCount,
    COALESCE(asales.TotalRevenue, 0) AS TotalRevenue,
    CASE 
        WHEN asales.OrderCount > 100 THEN 'High'
        WHEN asales.OrderCount BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS DemandCategory
FROM item i
LEFT JOIN AggregatedSales asales ON i.i_item_sk = asales.ws_item_sk
WHERE 
    i.i_category IN (
        SELECT DISTINCT i_category
        FROM item
        WHERE i_class = 'Electronics'
    )
ORDER BY TotalRevenue DESC
LIMIT 10;


WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS LatestSale
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    UNION ALL
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS PriceRank,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS LatestSale
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
GroupedSales AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS TotalQuantity,
        SUM(sd.ws_ext_sales_price) AS TotalSales,
        MAX(sd.PriceRank) AS MaxPriceRank,
        COUNT(CASE WHEN sd.LatestSale = 1 THEN 1 END) AS RecentSalesCount
    FROM
        SalesData sd
    GROUP BY
        sd.ws_item_sk
),
TopItems AS (
    SELECT
        gs.ws_item_sk,
        gs.TotalQuantity,
        gs.TotalSales,
        gs.MaxPriceRank,
        gs.RecentSalesCount,
        ROW_NUMBER() OVER (ORDER BY gs.TotalSales DESC) AS SalesRank
    FROM
        GroupedSales gs
)
SELECT
    ti.ws_item_sk,
    ti.TotalQuantity,
    ti.TotalSales,
    COALESCE(sm.sm_type, 'Unknown') AS ShipMode,
    (CASE 
        WHEN ti.MaxPriceRank = 1 THEN 'Premium Item'
        WHEN ti.RecentSalesCount > 0 THEN 'Recently Sold'
        ELSE 'Stale Item' 
    END) AS ItemStatus
FROM
    TopItems ti
LEFT JOIN 
    ship_mode sm ON ti.ws_item_sk = sm.sm_ship_mode_sk
WHERE
    ti.SalesRank <= 10
ORDER BY
    ti.TotalSales DESC NULLS LAST;

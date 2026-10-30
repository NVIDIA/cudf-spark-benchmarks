
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq,
        ROW_NUMBER() OVER(PARTITION BY d.d_year ORDER BY ws.ws_net_paid DESC) AS YearlyRank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
),
GroupedSales AS (
    SELECT 
        d.d_year,
        SUM(sd.ws_net_paid) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS UniqueOrders,
        AVG(ws_quantity) AS AverageItemsPerOrder
    FROM 
        SalesData sd
    JOIN 
        date_dim d ON sd.d_year = d.d_year
    GROUP BY 
        d.d_year
),
TopSales AS (
    SELECT 
        gs.d_year,
        gs.TotalSales,
        gs.UniqueOrders,
        gs.AverageItemsPerOrder,
        RANK() OVER (ORDER BY gs.TotalSales DESC) AS SalesRank
    FROM 
        GroupedSales gs
)
SELECT 
    ts.d_year,
    ts.TotalSales,
    ts.UniqueOrders,
    ts.AverageItemsPerOrder,
    COALESCE(sm.sm_type, 'N/A') AS ShipMode,
    CASE 
        WHEN ts.AverageItemsPerOrder > 5 THEN 'High'
        WHEN ts.AverageItemsPerOrder BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS OrderSizeCategory
FROM 
    TopSales ts
LEFT JOIN 
    ship_mode sm ON ts.UniqueOrders % 3 = sm.sm_ship_mode_sk
WHERE 
    ts.SalesRank <= 10
ORDER BY 
    ts.d_year DESC, ts.TotalSales DESC;


WITH MonthlySales AS (
    SELECT 
        d.d_year AS SalesYear,
        d.d_month_seq AS SalesMonth,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_net_profit) AS AvgNetProfit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2000
    GROUP BY 
        d.d_year, d.d_month_seq
),
CustomerSegmentation AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS IncomeBand,
        SUM(ms.TotalSales) AS TotalSalesBySegment
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        MonthlySales ms ON ms.SalesYear = EXTRACT(YEAR FROM DATE '2002-10-01') 
                          AND ms.SalesMonth = EXTRACT(MONTH FROM DATE '2002-10-01')
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS WarehouseSales,
        AVG(ws.ws_net_profit) AS AvgProfitPerWarehouse
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.IncomeBand,
    cs.TotalSalesBySegment,
    wp.WarehouseSales,
    wp.AvgProfitPerWarehouse
FROM 
    CustomerSegmentation cs
JOIN 
    WarehousePerformance wp ON TRUE
ORDER BY 
    cs.TotalSalesBySegment DESC, wp.WarehouseSales DESC
LIMIT 100;


WITH SalesData AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_sales_price) AS AvgSalesPrice
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_web_site_sk, ws.ws_sold_date_sk
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(sd.TotalSales) AS TotalWarehouseSales,
        COUNT(sd.TotalOrders) AS TotalWarehouseOrders
    FROM 
        SalesData sd
    JOIN 
        warehouse w ON sd.ws_web_site_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    w.w_warehouse_id,
    w.TotalWarehouseSales,
    w.TotalWarehouseOrders,
    RANK() OVER (ORDER BY w.TotalWarehouseSales DESC) AS SalesRank,
    CASE 
        WHEN w.TotalWarehouseSales > 100000 THEN 'High Performer'
        ELSE 'Needs Improvement'
    END AS PerformanceStatus
FROM 
    WarehouseSales w
ORDER BY 
    w.TotalWarehouseSales DESC;

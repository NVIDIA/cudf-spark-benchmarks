
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk AS SoldDate,
        ws.ws_item_sk AS ItemID,
        ws.ws_quantity AS QuantitySold,
        ws.ws_net_paid AS TotalRevenue,
        w.w_warehouse_id AS WarehouseID,
        c.c_customer_id AS CustomerID,
        cd.cd_gender AS CustomerGender,
        cd.cd_marital_status AS MaritalStatus,
        dd.d_year AS SaleYear,
        dd.d_month_seq AS SaleMonth,
        dd.d_week_seq AS SaleWeek
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
)

SELECT 
    SaleYear,
    SaleMonth,
    SaleWeek,
    WarehouseID,
    CustomerGender,
    MaritalStatus,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    SUM(QuantitySold) AS TotalQuantitySold,
    SUM(TotalRevenue) AS TotalRevenueGenerated
FROM 
    SalesData
GROUP BY 
    SaleYear, SaleMonth, SaleWeek, WarehouseID, CustomerGender, MaritalStatus
ORDER BY 
    SaleYear, SaleMonth, SaleWeek, WarehouseID;

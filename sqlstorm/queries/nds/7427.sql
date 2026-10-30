
WITH MonthlySales AS (
    SELECT 
        EXTRACT(MONTH FROM d.d_date) AS SalesMonth,
        EXTRACT(YEAR FROM d.d_date) AS SalesYear,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_net_paid) AS AvgOrderValue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        EXTRACT(MONTH FROM d.d_date), EXTRACT(YEAR FROM d.d_date)
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS TotalSpent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        TotalSpent DESC
    LIMIT 10
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS WarehouseTotalSales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_name
)
SELECT 
    ms.SalesYear,
    ms.SalesMonth,
    ms.TotalSales,
    ms.TotalOrders,
    ms.AvgOrderValue,
    tc.c_first_name,
    tc.c_last_name,
    tc.TotalSpent,
    ws.WarehouseTotalSales
FROM 
    MonthlySales ms
CROSS JOIN 
    TopCustomers tc
JOIN 
    WarehouseSales ws ON 1=1
WHERE 
    ms.TotalSales > 10000
ORDER BY 
    ms.SalesYear DESC,
    ms.SalesMonth DESC,
    tc.TotalSpent DESC;

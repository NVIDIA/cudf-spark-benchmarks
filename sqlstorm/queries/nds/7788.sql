
WITH SalesSummary AS (
    SELECT 
        d.d_year AS SaleYear,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_quantity) AS TotalQuantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS UniqueCustomers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        d.d_year
),
AvgSales AS (
    SELECT 
        SaleYear,
        TotalSales,
        TotalOrders,
        TotalQuantity,
        UniqueCustomers,
        TotalSales / NULLIF(TotalOrders, 0) AS AvgSalesPerOrder,
        TotalSales / NULLIF(UniqueCustomers, 0) AS AvgSalesPerCustomer
    FROM 
        SalesSummary
)
SELECT 
    SaleYear,
    TotalSales,
    TotalOrders,
    TotalQuantity,
    UniqueCustomers,
    AvgSalesPerOrder,
    AvgSalesPerCustomer
FROM 
    AvgSales
ORDER BY 
    SaleYear;


WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.avg_profit,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
),
WarehouseShipping AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_quantity) AS total_items_shipped,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    tc.c_customer_sk,
    tc.total_sales,
    tc.avg_profit,
    ws.total_items_shipped,
    ws.total_orders
FROM 
    TopCustomers tc
JOIN 
    WarehouseShipping ws ON ws.total_items_shipped > 100
WHERE 
    tc.sales_rank <= 50
ORDER BY 
    tc.total_sales DESC;

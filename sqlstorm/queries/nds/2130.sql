
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        *
    FROM 
        CustomerSales 
    WHERE 
        sales_rank <= 10
), 
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_paid) AS warehouse_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_sales, 
    tc.order_count,
    ws.warehouse_sales,
    ws.total_orders,
    ws.avg_order_value,
    CASE 
        WHEN tc.total_sales > ws.avg_order_value THEN 'High Value'
        ELSE 'Regular Value'
    END AS customer_type
FROM 
    TopCustomers tc
JOIN 
    WarehouseSales ws ON tc.c_customer_sk IN (
        SELECT 
            DISTINCT ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_net_paid > 0
    )
ORDER BY 
    tc.total_sales DESC, ws.warehouse_sales DESC;


WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    COALESCE(w.w_warehouse_name, 'No Warehouse') AS warehouse_name,
    (
        SELECT 
            COUNT(DISTINCT wr.wr_order_number)
        FROM 
            web_returns wr
        WHERE 
            wr.wr_returning_customer_sk = t.c_customer_sk
    ) AS total_returns
FROM 
    TopCustomers t
LEFT JOIN 
    warehouse w ON t.c_customer_sk = w.w_warehouse_sk 
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;

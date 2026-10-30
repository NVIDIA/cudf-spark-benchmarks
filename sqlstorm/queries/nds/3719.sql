
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459420 AND 2459430
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.total_spent,
        cp.order_count
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_customer_sk
    WHERE 
        cp.rn <= 10
),
WarehouseStats AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue
    FROM 
        warehouse w
    LEFT JOIN 
        store s ON s.s_store_sk = w.w_warehouse_sk
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    ws.w_warehouse_name,
    tc.total_spent,
    ws.total_sales,
    ws.total_revenue,
    CASE 
        WHEN ws.total_revenue IS NULL THEN 'NO SALES'
        ELSE 'SALES EXIST'
    END AS sales_status,
    COALESCE(tc.total_spent, 0) / NULLIF(ws.total_sales, 0) AS avg_spent_per_sale
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    WarehouseStats ws ON tc.c_customer_sk = ws.w_warehouse_sk
WHERE 
    (tc.total_spent IS NOT NULL OR ws.total_sales IS NOT NULL)
ORDER BY 
    total_spent DESC, total_revenue DESC;

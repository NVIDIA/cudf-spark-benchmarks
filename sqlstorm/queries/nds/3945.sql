
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid) AS warehouse_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
SalesAnalysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.order_count,
        cs.total_spent,
        w.warehouse_sales,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'No Sales'
            WHEN cs.total_spent > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM 
        CustomerSales cs
    LEFT JOIN 
        WarehouseSales w ON cs.c_customer_sk = w.w_warehouse_sk
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.order_count,
    COALESCE(sa.total_spent, 0) AS total_spent,
    COALESCE(sa.warehouse_sales, 0) AS warehouse_sales,
    sa.customer_type
FROM 
    SalesAnalysis sa
ORDER BY 
    sa.total_spent DESC, sa.order_count DESC
LIMIT 100;

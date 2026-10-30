
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
AggregateSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS warehouse_total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name,
        cs.total_web_sales,
        CASE 
            WHEN cs.total_web_sales IS NULL THEN 'No Sales'
            WHEN cs.total_web_sales >= 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_category
    FROM 
        CustomerSales cs
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_web_sales,
    hvc.customer_category,
    asls.warehouse_total_sales,
    asls.avg_net_paid,
    asls.max_profit
FROM 
    HighValueCustomers hvc
INNER JOIN 
    AggregateSales asls ON hvc.total_web_sales > 1000 
ORDER BY 
    hvc.total_web_sales DESC
LIMIT 10;

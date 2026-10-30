WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        MAX(ws.ws_net_profit) AS max_order_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        cs.max_order_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        (SELECT c_customer_id AS customer_id FROM customer WHERE c_birth_month = 12) c ON cs.c_customer_id = c.customer_id
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.total_orders,
    tc.avg_order_value,
    tc.max_order_profit,
    (SELECT COUNT(*) FROM customer cc WHERE cc.c_birth_month = 12) AS total_december_birthdays
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
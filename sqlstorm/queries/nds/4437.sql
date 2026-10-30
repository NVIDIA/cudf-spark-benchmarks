
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_spent,
        cs.total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs.total_orders ORDER BY cs.total_spent DESC) AS order_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_orders > (SELECT AVG(total_orders) FROM CustomerSales)
),
ReturnStats AS (
    SELECT 
        wr_order_number,
        SUM(wr_return_amt) AS total_returned,
        SUM(wr_return_tax) AS total_return_tax,
        COUNT(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_order_number
    HAVING 
        SUM(wr_return_amt) > 0
)
SELECT 
    hvc.c_customer_id,
    hvc.total_spent,
    hvc.total_orders,
    rh.total_returned,
    rh.total_return_tax,
    rh.total_returns
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    ReturnStats rh ON hvc.total_orders = rh.wr_order_number
WHERE 
    hvc.order_rank <= 10
ORDER BY 
    hvc.total_spent DESC;

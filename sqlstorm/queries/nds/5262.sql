
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cus.c_customer_sk,
        cus.c_first_name,
        cus.c_last_name,
        cus.total_quantity,
        cus.total_spent,
        cus.order_count,
        DENSE_RANK() OVER (ORDER BY cus.total_spent DESC) AS rank
    FROM 
        CustomerOrderSummary cus
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_quantity,
    t.total_spent,
    t.order_count
FROM 
    TopCustomers t
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_spent DESC;

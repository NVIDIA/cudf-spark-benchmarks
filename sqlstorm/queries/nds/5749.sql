
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        MAX(ws.ws_sales_price) AS max_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.total_orders,
        cs.avg_order_value,
        cs.max_order_value,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        (SELECT c_customer_id, c_first_name, c_last_name 
         FROM customer) c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    total_spent,
    total_orders,
    avg_order_value,
    max_order_value
FROM 
    TopCustomers
WHERE 
    rank <= 10
ORDER BY 
    total_spent DESC;

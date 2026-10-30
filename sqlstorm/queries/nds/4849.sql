WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 365 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),  
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_spent,
        total_orders,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerSales
    WHERE 
        total_spent > 1000 
), 
RecentActivity AS (
    SELECT 
        c.c_customer_sk,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date_sk,
        SUM(ws.ws_net_paid) AS total_recent_spent
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 0) 
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    hvc.total_orders,
    ra.total_recent_spent,
    d.d_date
FROM 
    HighValueCustomers hvc
LEFT JOIN RecentActivity ra ON hvc.c_customer_sk = ra.c_customer_sk
JOIN date_dim d ON ra.last_purchase_date_sk = d.d_date_sk
WHERE 
    hvc.customer_rank <= 10 
ORDER BY 
    hvc.total_spent DESC;
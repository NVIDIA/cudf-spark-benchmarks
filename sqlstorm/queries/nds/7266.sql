
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.total_orders,
        cs.last_purchase_date
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count,
    SUM(hvc.total_orders) AS total_orders_placed,
    AVG(hvc.total_spent) AS avg_spent_per_customer
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
GROUP BY 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    high_value_customer_count DESC, 
    avg_spent_per_customer DESC
LIMIT 10;

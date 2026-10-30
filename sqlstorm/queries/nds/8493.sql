
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        c.c_customer_id
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_profit,
        cs.total_orders,
        cs.avg_order_value
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_profit > (SELECT AVG(total_profit) FROM CustomerSales)
    ORDER BY 
        cs.total_profit DESC
    LIMIT 10
) 
SELECT 
    c.c_first_name,
    c.c_last_name,
    hvc.total_profit,
    hvc.total_orders,
    hvc.avg_order_value
FROM 
    HighValueCustomers hvc
JOIN 
    customer c ON hvc.c_customer_id = c.c_customer_id
ORDER BY 
    hvc.total_profit DESC;

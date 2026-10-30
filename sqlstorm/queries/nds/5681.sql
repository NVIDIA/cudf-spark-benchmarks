WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN 2451545 AND 2451545 + 365  
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_net_profit,
        total_orders,
        avg_sales_price,
        DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS customer_rank
    FROM 
        CustomerSales
),
HighValueCustomers AS (
    SELECT 
        c_customer_id,
        total_net_profit,
        total_orders,
        avg_sales_price
    FROM 
        TopCustomers
    WHERE 
        customer_rank <= 100  
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hvc.total_net_profit,
    hvc.total_orders,
    hvc.avg_sales_price,
    d.d_year,
    COUNT(ws.ws_order_number) AS detailed_orders
FROM 
    customer c
JOIN 
    HighValueCustomers hvc ON c.c_customer_id = hvc.c_customer_id
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year >= 1998  
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hvc.total_net_profit,
    hvc.total_orders,
    hvc.avg_sales_price,
    d.d_year
ORDER BY 
    hvc.total_net_profit DESC, 
    detailed_orders DESC
LIMIT 50;

WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_orders,
        cs.total_sales,
        cs.avg_profit,
        CASE 
            WHEN cs.total_sales > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_orders > 5
)
SELECT 
    hvc.customer_type, 
    hvc.total_orders,
    hvc.total_sales,
    hvc.avg_profit,
    COUNT(hvc.c_customer_id) AS number_of_customers
FROM 
    HighValueCustomers hvc
GROUP BY 
    hvc.customer_type, hvc.total_orders, hvc.total_sales, hvc.avg_profit
ORDER BY 
    hvc.total_sales DESC;

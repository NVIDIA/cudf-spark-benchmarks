WITH SalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451565 AND 2451889 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        SalesData
    WHERE 
        total_net_profit > 1000
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_net_profit,
    hvc.total_orders,
    hvc.avg_order_value,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip
FROM 
    HighValueCustomers hvc
JOIN 
    CustomerAddresses ca ON hvc.c_customer_sk = ca.c_customer_sk
WHERE 
    hvc.profit_rank <= 100
ORDER BY 
    hvc.total_net_profit DESC
LIMIT 10 OFFSET 0;
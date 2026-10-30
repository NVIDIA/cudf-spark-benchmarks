
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
High_Value_Customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_net_profit,
        total_orders,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        Customer_Sales
    WHERE 
        total_net_profit > (SELECT AVG(total_net_profit) FROM Customer_Sales)
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_net_profit,
    hvc.total_orders,
    CASE 
        WHEN hvc.profit_rank <= 10 THEN 'Top Customer'
        WHEN hvc.profit_rank <= 50 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM 
    High_Value_Customers hvc
LEFT JOIN 
    customer_demographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
WHERE 
    cd.cd_gender = 'F'
    AND ca.ca_state = 'CA'
ORDER BY 
    hvc.total_net_profit DESC;

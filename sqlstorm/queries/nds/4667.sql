
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerSales) 
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(CAST(CASE WHEN hvc.profit_rank IS NOT NULL THEN hvc.total_net_profit ELSE 0 END AS DECIMAL(10, 2)), 0) AS net_profit,
    COALESCE(hvc.total_orders, 0) AS order_count,
    CASE 
        WHEN hvc.profit_rank IS NOT NULL THEN 'High Value'
        ELSE 'Regular'
    END AS customer_category
FROM 
    customer AS c
LEFT JOIN 
    HighValueCustomers AS hvc ON c.c_customer_sk = hvc.c_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    net_profit DESC, c.c_last_name;

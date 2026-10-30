
WITH  TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 1000
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(cs.cs_net_profit) > 1000
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(tc.total_profit, 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN (
        SELECT 
            c_customer_sk, 
            SUM(total_profit) AS total_profit 
        FROM 
            TopCustomers 
        GROUP BY 
            c_customer_sk
    ) tc ON c.c_customer_sk = tc.c_customer_sk
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    fc.total_profit,
    CASE 
        WHEN fc.total_profit > 5000 THEN 'Gold'
        WHEN fc.total_profit BETWEEN 2000 AND 5000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_tax) AS total_tax_collected
FROM 
    FilteredCustomers fc
LEFT JOIN 
    web_sales ws ON fc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    fc.c_customer_sk, 
    fc.c_first_name, 
    fc.c_last_name, 
    fc.total_profit
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY 
    total_profit DESC;

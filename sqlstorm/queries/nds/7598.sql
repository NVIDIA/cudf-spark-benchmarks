
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        Customer_Sales AS cs
)
SELECT 
    tc.c_customer_sk,
    tc.total_profit,
    ca.ca_city,
    ca.ca_state
FROM 
    Top_Customers AS tc
JOIN 
    customer AS c ON tc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.profit_rank <= 10;


WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
Top_Customers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        Customer_Sales cs
    JOIN 
        (SELECT 
            c_customer_sk, 
            c_first_name, 
            c_last_name 
         FROM 
            customer
         WHERE 
            c_current_cdemo_sk IS NOT NULL) c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.first_name,
    tc.last_name,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(tc.total_orders, 0) AS total_orders,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS customer_category
FROM 
    Top_Customers tc
WHERE 
    tc.rank IS NOT NULL
ORDER BY 
    total_spent DESC;

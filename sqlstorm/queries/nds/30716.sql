
WITH RecursiveSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 3
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        * 
    FROM 
        RecursiveSummary
    WHERE 
        rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    COALESCE(tc.total_net_profit, 0) AS net_profit,
    CASE 
        WHEN tc.total_quantity > 100 THEN 'High Value'
        WHEN tc.total_quantity BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    (SELECT 
        SUM(ss.ss_net_profit) 
     FROM 
        store_sales ss 
     WHERE 
        ss.ss_customer_sk = tc.c_customer_sk
        AND ss.ss_sold_date_sk IN (
            SELECT d2.d_date_sk
            FROM date_dim d2 
            WHERE d2.d_year = 2023 
              AND d2.d_month_seq BETWEEN 1 AND 3
        )
    ) AS total_store_sales_profit
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_net_profit DESC;

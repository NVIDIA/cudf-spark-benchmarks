
WITH  Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
Customer_Analytics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_birth_year,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, c.c_birth_year
),
Top_Customers AS (
    SELECT 
        customer_name,
        total_orders,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        Customer_Analytics
    WHERE 
        total_spent IS NOT NULL
)
SELECT 
    t.customer_name, 
    t.total_orders, 
    t.total_spent, 
    s.total_net_profit AS web_sales_net_profit
FROM 
    Top_Customers t
LEFT JOIN 
    (SELECT 
        ws_item_sk,
        SUM(total_net_profit) AS total_net_profit 
     FROM 
        Sales_CTE 
     WHERE 
        item_rank = 1 
     GROUP BY 
        ws_item_sk) s ON s.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_sold_date_sk BETWEEN (SELECT MIN(ws_sold_date_sk) FROM web_sales) AND (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    )
WHERE 
    t.customer_rank <= 10
ORDER BY 
    t.total_spent DESC;

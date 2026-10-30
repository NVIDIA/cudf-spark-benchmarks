
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_item_sk, 
        ws_order_number
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cs.order_count,
        cs.total_spent
    FROM 
        customer c
    JOIN 
        CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(SUM(s.total_profit), 0) AS total_profit,
    CASE 
        WHEN hvc.order_count > 5 THEN 'Loyal Customer'
        ELSE 'Occasional Customer'
    END AS customer_category,
    CASE 
        WHEN hvc.total_spent IS NULL THEN 'No Spend'
        ELSE 'Spent'
    END AS spend_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    SalesCTE s ON hvc.c_customer_sk = s.ws_item_sk
GROUP BY 
    hvc.c_customer_sk, 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.order_count, 
    hvc.total_spent
ORDER BY 
    total_profit DESC, 
    hvc.c_last_name ASC

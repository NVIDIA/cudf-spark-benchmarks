
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
BestCustomers AS (
    SELECT 
        cs.*,
        CASE 
            WHEN cs.gender_rank <= 5 THEN 'Top Performer'
            ELSE 'Regular Customer'
        END AS customer_level
    FROM 
        CustomerStats cs
)
SELECT 
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.cd_gender,
    b.cd_marital_status,
    b.total_net_profit,
    b.total_orders,
    b.customer_level,
    COALESCE(b.total_net_profit * 0.1, 0) AS potential_bonus,
    ROW_NUMBER() OVER (ORDER BY b.total_net_profit DESC) AS global_rank
FROM 
    BestCustomers b
WHERE 
    b.total_orders > 1
ORDER BY 
    b.total_net_profit DESC
LIMIT 10;


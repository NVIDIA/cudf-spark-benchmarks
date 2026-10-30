WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent_per_order,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopSpenders AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_orders,
    cs.total_spent,
    cs.avg_spent_per_order,
    TOP.total_spent AS top_spender_amount,
    CASE 
        WHEN cs.order_rank <= 5 THEN 'Top 5% Gender Group Spenders'
        ELSE 'Other'
    END AS category
FROM 
    CustomerStats cs
LEFT JOIN 
    (SELECT * FROM TopSpenders) TOP ON cs.c_first_name = TOP.c_first_name AND cs.c_last_name = TOP.c_last_name
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
ORDER BY 
    cs.total_spent DESC;
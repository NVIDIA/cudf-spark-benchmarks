
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk
),
Customer_Demo AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender AS gender, 
        cd.cd_marital_status AS marital_status, 
        cd.cd_education_status
    FROM 
        customer_demographics cd
)
SELECT 
    cd.gender,
    cd.marital_status,
    COUNT(cs.c_customer_sk) AS customer_count,
    AVG(cs.order_count) AS avg_orders,
    AVG(cs.total_net_profit) AS avg_net_profit,
    AVG(cs.avg_spent) AS avg_spent
FROM 
    Customer_Sales cs
JOIN 
    Customer_Demo cd ON cs.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.gender, cd.marital_status
ORDER BY 
    customer_count DESC, avg_net_profit DESC
LIMIT 10;

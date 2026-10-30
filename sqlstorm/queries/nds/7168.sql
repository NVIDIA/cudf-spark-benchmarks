
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_within_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.cd_marital_status,
        r.total_net_profit
    FROM 
        RankedCustomers r
    WHERE 
        r.rank_within_gender <= 10
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.cd_gender,
    h.cd_marital_status,
    h.total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) AS avg_order_value
FROM 
    HighValueCustomers h
JOIN 
    web_sales ws ON ws.ws_ship_customer_sk = h.c_customer_sk
GROUP BY 
    h.c_customer_sk, h.c_first_name, h.c_last_name, h.cd_gender, h.cd_marital_status, h.total_net_profit
ORDER BY 
    h.total_net_profit DESC
LIMIT 50;

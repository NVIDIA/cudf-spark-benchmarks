
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
CustomerPerformance AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.total_orders,
        rc.total_profit,
        DENSE_RANK() OVER (ORDER BY rc.total_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (ORDER BY rc.total_orders DESC) AS rank_orders
    FROM 
        RankedCustomers rc
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    cp.cd_gender,
    cp.cd_marital_status,
    cp.cd_education_status,
    cp.total_orders,
    cp.total_profit,
    cp.rank_profit,
    cp.rank_orders
FROM 
    CustomerPerformance cp
WHERE 
    cp.rank_profit <= 10 OR cp.rank_orders <= 10
ORDER BY 
    cp.rank_profit, cp.rank_orders;

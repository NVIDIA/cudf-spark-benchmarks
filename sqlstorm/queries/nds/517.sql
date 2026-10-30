
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
HighProfit AS (
    SELECT 
        ri.ws_item_sk,
        SUM(ri.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ri
    WHERE 
        ri.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ri.ws_item_sk
    HAVING 
        SUM(ri.ws_net_profit) > 1000
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ci.cd_gender,
    ci.total_orders,
    ci.avg_profit,
    COALESCE(hp.total_net_profit, 0) AS item_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    HighProfit hp ON hp.ws_item_sk IS NOT NULL
INNER JOIN 
    customer c ON ci.c_customer_sk = c.c_customer_sk
WHERE 
    ci.avg_profit IS NOT NULL
ORDER BY 
    item_profit DESC
LIMIT 100;

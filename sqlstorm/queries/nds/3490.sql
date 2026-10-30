
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(COUNT(DISTINCT ws.ws_order_number), 0) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
Ranking AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        cs.total_orders,
        cs.total_net_profit,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        CustomerSummary cs
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_purchase_estimate,
    r.total_orders,
    r.total_net_profit,
    r.profit_rank
FROM 
    Ranking r
WHERE 
    r.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerSummary) 
    AND r.profit_rank <= 10
ORDER BY 
    r.cd_gender, 
    r.total_net_profit DESC;

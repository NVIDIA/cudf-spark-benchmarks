
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(wr.wr_return_amt) AS total_web_return_amt
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender
),
profitable_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_profit,
        cs.total_web_returns,
        cs.total_web_return_amt,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS rank_profit
    FROM 
        customer_summary cs
    WHERE 
        cs.total_profit > 0
),
web_order_stats AS (
    SELECT 
        ws.ws_ship_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_ship_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    p.c_customer_sk,
    p.c_first_name,
    p.c_last_name,
    p.total_orders,
    p.total_profit,
    p.total_web_returns,
    p.total_web_return_amt,
    COALESCE(wos.total_orders, 0) AS daily_orders,
    COALESCE(wos.total_net_profit, 0) AS daily_net_profit
FROM 
    profitable_customers p
FULL OUTER JOIN 
    web_order_stats wos ON p.total_orders > 0 
ORDER BY 
    p.rank_profit, daily_net_profit DESC
LIMIT 100;

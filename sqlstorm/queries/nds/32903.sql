
WITH  sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_moy IN (SELECT d_moy FROM date_dim WHERE d_year = 2023 AND d_holiday = 'Y')
    GROUP BY 
        ws.ws_sold_date_sk
), 
customer_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS customer_net_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    ss.ws_sold_date_sk,
    ss.total_quantity,
    ss.total_net_profit,
    cr.c_first_name,
    cr.c_last_name,
    cr.customer_net_profit,
    cr.gender_rank
FROM 
    sales_summary ss
LEFT JOIN 
    customer_rank cr ON ss.profit_rank = cr.gender_rank
WHERE 
    ss.total_net_profit > (
        SELECT AVG(total_net_profit) 
        FROM sales_summary 
    )
ORDER BY 
    ss.total_net_profit DESC 
LIMIT 10;

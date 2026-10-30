
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_profit,
        rc.order_count
    FROM 
        ranked_customers AS rc
    WHERE 
        rc.rank <= 10
)
SELECT 
    tc.cd_gender,
    tc.cd_marital_status,
    AVG(tc.total_profit) AS avg_profit,
    SUM(tc.order_count) AS total_orders
FROM 
    top_customers AS tc
GROUP BY 
    tc.cd_gender, tc.cd_marital_status
ORDER BY 
    avg_profit DESC;

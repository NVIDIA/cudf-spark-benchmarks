
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
monthly_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        sales_data sd
    JOIN 
        date_dim dd ON sd.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        sd.rn = 1
    GROUP BY 
        d_year, d_month_seq
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws_net_profit) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) as rank
    FROM 
        customer_summary
)
SELECT 
    mc.d_year,
    mc.d_month_seq,
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    mc.total_quantity,
    mc.total_profit,
    tc.orders_count
FROM 
    monthly_sales mc
JOIN 
    top_customers tc ON mc.d_year = 2022
WHERE 
    tc.rank <= 10
ORDER BY 
    mc.total_profit DESC;


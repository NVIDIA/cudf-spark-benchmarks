
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_customer_sk = hd.hd_demo_sk
),
high_profit_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        ranked_sales AS rs
    JOIN 
        customer_info AS ci ON rs.ws_bill_customer_sk = ci.c_customer_sk
    WHERE 
        rs.profit_rank <= 5
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    hpc.c_customer_sk,
    hpc.c_first_name,
    hpc.c_last_name,
    hpc.total_net_profit,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    high_profit_customers AS hpc
LEFT JOIN 
    income_band AS ib ON hpc.total_net_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE 
    hpc.total_net_profit IS NOT NULL
ORDER BY 
    hpc.total_net_profit DESC
LIMIT 10;

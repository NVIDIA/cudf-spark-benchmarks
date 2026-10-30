
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        HYPOTHETICAL_INCOME_BAND.ib_lower_bound AS income_lower,
        HYPOTHETICAL_INCOME_BAND.ib_upper_bound AS income_upper,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band HYPOTHETICAL_INCOME_BAND ON hd.hd_income_band_sk = HYPOTHETICAL_INCOME_BAND.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
combined_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.income_lower,
        cs.income_upper,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(ss.order_count, 0) AS order_count,
        cs.gender_rank
    FROM 
        customer_summary cs
    LEFT JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_sold_date_sk
)

SELECT 
    *,
    CASE 
        WHEN total_net_profit > 1000 THEN 'High Value'
        WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    CASE 
        WHEN c_first_name IS NULL THEN 'Unknown'
        ELSE c_first_name
    END AS display_name
FROM 
    combined_summary
WHERE 
    (income_lower IS NOT NULL AND income_upper IS NOT NULL)
    AND gender_rank <= 10
ORDER BY 
    total_net_profit DESC, c_last_name;


WITH customer_info AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
date_summary AS (
    SELECT 
        d.d_year,
        d.d_quarter_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_quarter_seq
),
average_income AS (
    SELECT 
        cd.cd_marital_status,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_marital_status
),
result AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.total_net_profit,
        ds.d_year,
        ds.d_quarter_seq,
        ds.total_orders,
        ai.avg_income_band
    FROM 
        customer_info ci
    JOIN 
        date_summary ds ON ds.total_orders > 0
    JOIN 
        average_income ai ON ci.cd_marital_status = ai.cd_marital_status
)

SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_net_profit,
    d_year,
    d_quarter_seq,
    total_orders,
    avg_income_band
FROM 
    result
WHERE 
    total_net_profit > 1000
ORDER BY 
    total_net_profit DESC, d_year DESC, full_name;

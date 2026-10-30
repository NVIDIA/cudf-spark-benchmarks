
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 

customer_info AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status,
        COALESCE(cd_credit_rating, 'Unknown') AS credit_rating,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY cd_credit_rating ORDER BY c.c_birth_year DESC) AS credit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 

time_analysis AS (
    SELECT 
        d.d_year,
        AVG(t.t_time) AS avg_time,
        COUNT(DISTINCT d.d_date) AS total_days,
        RANK() OVER (ORDER BY AVG(t.t_time) DESC) AS time_rank
    FROM 
        date_dim d
    JOIN 
        time_dim t ON d.d_date_sk = t.t_time_sk
    WHERE 
        d.d_year > 2020 AND d.d_holiday = 'Y'
    GROUP BY 
        d.d_year
)

SELECT 
    ci.marital_status,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    SUM(sd.total_quantity) AS total_web_sales_quantity,
    NULLIF(SUM(sd.total_net_profit), 0) AS total_web_sales_net_profit,
    COALESCE(MAX(ta.avg_time), 0) AS highest_avg_time,
    EXISTS (
        SELECT 1 
        FROM sales_data sd2 
        WHERE sd2.profit_rank = 1 
            AND sd2.total_net_profit > 10000
    ) AS high_profit_item_exists
FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    time_analysis ta ON ci.credit_rank <= ta.time_rank
GROUP BY 
    ci.marital_status
HAVING 
    COUNT(DISTINCT ci.c_customer_sk) > 5
ORDER BY 
    customer_count DESC 
    NULLS LAST

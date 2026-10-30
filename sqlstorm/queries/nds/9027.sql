
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 
    GROUP BY 
        c.c_customer_id, 
        c.c_birth_year, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
),
income_band_stats AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM household_demographics h
    JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE h.hd_income_band_sk IS NOT NULL
    GROUP BY h.hd_income_band_sk
),
final_report AS (
    SELECT 
        cd.c_customer_id,
        cd.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.customer_count,
        ib.avg_purchase_estimate,
        cd.total_net_profit
    FROM customer_data cd
    LEFT JOIN income_band_stats ib ON cd.cd_purchase_estimate BETWEEN ib.hd_income_band_sk AND ib.hd_income_band_sk + 10000
)
SELECT 
    c.cd_gender,
    COUNT(*) AS num_customers,
    AVG(c.total_net_profit) AS avg_net_profit,
    SUM(c.customer_count) AS total_customers_in_income_band
FROM final_report c
GROUP BY c.cd_gender
ORDER BY avg_net_profit DESC;

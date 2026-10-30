
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' 
      AND hd.hd_income_band_sk IS NOT NULL
      AND c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count
),
profit_analysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.hd_income_band_sk,
        ci.hd_dep_count,
        ci.hd_vehicle_count,
        ci.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ci.hd_income_band_sk ORDER BY ci.total_net_profit DESC) AS rank_profit
    FROM customer_info ci
)
SELECT 
    pa.c_customer_sk,
    pa.c_first_name,
    pa.c_last_name,
    pa.cd_marital_status,
    pa.cd_education_status,
    pa.cd_purchase_estimate,
    pa.hd_income_band_sk,
    pa.hd_dep_count,
    pa.hd_vehicle_count,
    pa.total_net_profit
FROM profit_analysis pa
WHERE pa.rank_profit <= 10
ORDER BY pa.hd_income_band_sk, pa.total_net_profit DESC;

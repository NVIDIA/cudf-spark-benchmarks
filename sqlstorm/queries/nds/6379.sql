
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        d.d_year,
        d.d_month_seq,
        d.d_dow
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    COUNT(sd.ws_item_sk) AS items_bought,
    SUM(sd.total_quantity_sold) AS total_quantity_sold,
    SUM(sd.total_sales) AS total_sales,
    SUM(sd.total_profit) AS total_profit,
    MAX(ci.d_year) AS last_purchase_year,
    MAX(ci.d_month_seq) AS last_purchase_month,
    MAX(ci.d_dow) AS last_purchase_day_of_week
FROM customer_info ci
LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
WHERE ci.hd_income_band_sk IS NOT NULL
GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate, ci.hd_income_band_sk
HAVING SUM(sd.total_sales) > 1000
ORDER BY total_sales DESC;

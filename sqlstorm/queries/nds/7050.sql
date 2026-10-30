
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), sales_data AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_tax) AS total_tax,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), combined_data AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.hd_income_band_sk,
        ci.hd_buy_potential,
        sd.total_sales,
        sd.order_count,
        sd.total_tax,
        sd.total_discount
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    hd.hd_income_band_sk,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    AVG(cd.total_sales) AS avg_sales,
    SUM(cd.total_tax) AS total_taxes_collected,
    AVG(cd.order_count) AS avg_orders,
    SUM(cd.total_discount) AS total_discount_given
FROM combined_data cd
JOIN household_demographics hd ON cd.hd_income_band_sk = hd.hd_income_band_sk
GROUP BY hd.hd_income_band_sk
ORDER BY hd.hd_income_band_sk;

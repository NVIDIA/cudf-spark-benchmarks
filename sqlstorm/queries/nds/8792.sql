
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
demographics_sales AS (
    SELECT 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name, 
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.hd_income_band_sk,
        ci.hd_buy_potential,
        ss.total_sales,
        ss.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ci.hd_income_band_sk ORDER BY ss.total_sales DESC) AS ranking
    FROM customer_info ci
    JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    ds.c_customer_sk,
    ds.c_first_name,
    ds.c_last_name,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_credit_rating,
    ds.hd_income_band_sk,
    ds.hd_buy_potential,
    ds.total_sales,
    ds.total_orders
FROM demographics_sales ds
WHERE ds.ranking <= 10
ORDER BY ds.hd_income_band_sk, ds.total_sales DESC;

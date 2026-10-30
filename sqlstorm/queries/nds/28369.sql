
WITH address_data AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
full_report AS (
    SELECT 
        ca.ca_address_sk,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        sd.total_sales,
        sd.total_orders,
        cu.full_name,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.cd_purchase_estimate,
        cu.hd_income_band_sk,
        cu.hd_buy_potential
    FROM address_data ca
    LEFT JOIN sales_data sd ON ca.ca_address_sk = sd.ws_bill_customer_sk
    LEFT JOIN customer_analysis cu ON cu.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    total_sales,
    total_orders,
    full_name,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    hd_income_band_sk,
    hd_buy_potential
FROM full_report
WHERE total_sales > 1000
ORDER BY total_sales DESC, ca_city;

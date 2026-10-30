
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT('Income Band: ', COALESCE(CAST(ib.ib_lower_bound AS STRING), 'N/A'), ' - ', COALESCE(CAST(ib.ib_upper_bound AS STRING), 'N/A')) AS income_band
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        MAX(ws_sales_price) AS max_sales_price,
        MIN(ws_sales_price) AS min_sales_price
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.income_band,
    sd.total_quantity,
    sd.total_profit,
    sd.max_sales_price,
    sd.min_sales_price
FROM customer c
JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
WHERE cd.cd_purchase_estimate > 5000
ORDER BY sd.total_profit DESC, c.c_last_name;

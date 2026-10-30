
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        REPLACE(c.c_email_address, '@', '[at]') AS email_obfuscated,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ai.full_address,
        ci.email_obfuscated,
        ci.cd_gender,
        ci.cd_marital_status,
        sd.total_sales,
        sd.order_count
    FROM CustomerDetails ci
    JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 100 THEN 'Low Spender'
        WHEN total_sales BETWEEN 100 AND 500 THEN 'Medium Spender'
        WHEN total_sales > 500 THEN 'High Spender'
    END AS spender_category
FROM FinalReport
ORDER BY total_sales DESC;


WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    CD.full_name,
    CD.cd_gender,
    CD.cd_marital_status,
    CD.cd_purchase_estimate,
    CD.cd_credit_rating,
    CD.cd_dep_count,
    AD.full_address,
    AD.ca_city,
    AD.ca_state,
    AD.ca_zip,
    AD.ca_country,
    COALESCE(SD.total_sales, 0) AS total_sales,
    COALESCE(SD.avg_profit, 0) AS avg_profit,
    CASE 
        WHEN SD.total_sales > 1000 THEN 'High Value Customer'
        WHEN SD.total_sales > 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM CustomerDetails CD
JOIN AddressDetails AD ON CD.c_customer_sk = AD.ca_address_sk
LEFT JOIN SalesData SD ON CD.c_customer_sk = SD.ws_bill_customer_sk
ORDER BY CD.cd_purchase_estimate DESC, CD.full_name;

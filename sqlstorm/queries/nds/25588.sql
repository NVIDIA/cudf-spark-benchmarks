
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        UPPER(TRIM(ca_city)) AS city,
        UPPER(TRIM(ca_state)) AS state,
        ca_zip AS zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ac.full_address,
        ac.city,
        ac.state,
        ac.zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
Benchmarking AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        sd.total_sales,
        ci.city,
        ci.state,
        ci.zip
    FROM CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COALESCE(total_sales, 0) AS total_sales,
    city,
    state,
    zip,
    LENGTH(full_name) AS name_length,
    LENGTH(city) AS city_length,
    LENGTH(state) AS state_length
FROM Benchmarking
ORDER BY total_sales DESC, name_length ASC
LIMIT 100;

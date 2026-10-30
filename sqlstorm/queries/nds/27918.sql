
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        SUBSTRING(cd_education_status, 1, 10) AS short_education_status
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)

SELECT
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.short_education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM CustomerDetails cd
JOIN customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN AddressDetails ad ON ad.ca_address_sk = ca.ca_address_sk
LEFT JOIN SalesDetails sd ON sd.ws_bill_customer_sk = cd.c_customer_sk
WHERE ad.ca_state = 'CA'
ORDER BY total_sales DESC, cd.full_name;

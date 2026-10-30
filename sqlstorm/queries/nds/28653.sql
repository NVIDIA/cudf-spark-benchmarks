
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(UPPER(SUBSTRING(ca_country, 1, 1)), LOWER(SUBSTRING(ca_country, 2))) AS formatted_country
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.formatted_country
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.formatted_country
FROM
    CustomerInfo ci
LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk 
ORDER BY 
    total_sales DESC, 
    ci.full_name ASC;

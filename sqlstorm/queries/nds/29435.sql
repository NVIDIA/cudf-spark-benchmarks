
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) END,
               ', ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip), ' ', TRIM(ca_country)) AS full_address
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ac.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        cd.customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY ws.ws_order_number, cd.customer_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    sd.ws_order_number,
    sd.customer_name,
    sd.cd_gender,
    sd.cd_marital_status,
    sd.total_sales,
    CASE 
        WHEN sd.total_sales > 1000 THEN 'High Value'
        WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM SalesData sd
WHERE sd.cd_gender = 'M' AND sd.cd_marital_status = 'S'
ORDER BY sd.total_sales DESC;

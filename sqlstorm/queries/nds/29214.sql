
WITH AddressParts AS (
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
CustomerFullName AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    GROUP BY ws.ws_order_number, ws.ws_bill_customer_sk
)
SELECT 
    cff.full_name,
    ap.full_address,
    ap.ca_city,
    ap.ca_state,
    ap.ca_zip,
    cff.cd_gender,
    cff.cd_marital_status,
    sd.total_quantity,
    sd.total_sales
FROM CustomerFullName cff
JOIN customer c ON c.c_customer_sk = cff.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN AddressParts ap ON ap.ca_address_sk = ca.ca_address_sk
JOIN SalesData sd ON sd.ws_bill_customer_sk = c.c_customer_sk
WHERE ap.ca_state = 'CA' 
    AND cff.cd_gender = 'F' 
    AND sd.total_sales > 1000
ORDER BY sd.total_sales DESC;


WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length
    FROM customer_address
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.ca_city,
        ad.ca_state,
        ad.full_address,
        ad.street_name_length
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cu.c_customer_sk,
    cu.c_first_name,
    cu.c_last_name,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.cd_purchase_estimate,
    cu.ca_city,
    cu.ca_state,
    cu.full_address,
    cu.street_name_length,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    CASE 
        WHEN sd.total_sales > 1000 THEN 'High Value Customer'
        WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM CustomerData cu
LEFT JOIN SalesData sd ON cu.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY cu.cd_purchase_estimate DESC, cu.c_last_name ASC, cu.c_first_name ASC;

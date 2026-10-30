
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),  
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ci.full_address,
        ci.ca_city,
        ci.ca_state
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN AddressConcat ci ON c.c_current_addr_sk = ci.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    ci.ca_city,
    ci.ca_state
FROM 
    CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ci.full_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    sd.total_sales, 
    sd.total_orders,
    ci.ca_city,
    ci.ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;

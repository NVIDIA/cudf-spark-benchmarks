
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_street_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ADD.full_street_address,
    ADD.ca_city,
    ADD.ca_state,
    ADD.ca_zip,
    CUST.full_customer_name,
    CUST.cd_gender,
    CUST.cd_marital_status,
    SUM(SALES.total_sales) AS total_spent,
    SUM(SALES.order_count) AS orders_placed,
    COUNT(DISTINCT ADD.ca_address_sk) AS unique_addresses
FROM 
    AddressParts ADD
JOIN 
    CustomerDetails CUST ON CUST.c_customer_sk = ADD.ca_address_sk
JOIN 
    SalesSummary SALES ON SALES.customer_id = ADD.ca_address_sk
GROUP BY 
    ADD.full_street_address, ADD.ca_city, ADD.ca_state, ADD.ca_zip, CUST.full_customer_name, CUST.cd_gender, CUST.cd_marital_status
ORDER BY 
    total_spent DESC
LIMIT 10;

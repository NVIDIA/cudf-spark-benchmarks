
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(NULLIF(ca_suite_number, ''), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_order_number,
        a.full_address,
        c.full_name,
        c.c_email_address
    FROM 
        web_sales ws
    JOIN 
        AddressDetails a ON ws.ws_ship_addr_sk = a.ca_address_sk
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
)

SELECT 
    COUNT(*) AS total_sales,
    SUM(ws_ext_sales_price) AS total_revenue,
    AVG(ws_sales_price) AS average_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    MIN(ws_sales_price) AS min_sales_price,
    full_address,
    COUNT(DISTINCT c_email_address) AS unique_customers
FROM 
    SalesData
GROUP BY 
    full_address
ORDER BY 
    total_revenue DESC
LIMIT 10;

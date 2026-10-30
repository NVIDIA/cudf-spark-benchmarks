
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DetailedSales AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.order_count, 0) AS order_count
    FROM 
        CustomerDetails c
    JOIN 
        AddressDetails a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.customer_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    order_count
FROM 
    DetailedSales
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC, order_count DESC
LIMIT 50;

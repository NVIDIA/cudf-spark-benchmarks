
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerFullNames AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
SalesInformation AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cfn.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        si.total_sales,
        si.order_count
    FROM 
        CustomerFullNames cfn
    JOIN 
        SalesInformation si ON cfn.c_customer_sk = si.ws_bill_customer_sk
    JOIN 
        addressdetails ad ON cfn.c_customer_sk = ad.ca_address_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CombinedData
ORDER BY 
    total_sales DESC;

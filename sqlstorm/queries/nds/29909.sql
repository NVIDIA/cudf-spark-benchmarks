
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip
    FROM 
        customer_address
), CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), CombinedData AS (
    SELECT 
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        a.full_address,
        a.city_state_zip,
        COALESCE(s.total_sales, 0) AS total_sales
    FROM 
        CustomerData c
    JOIN 
        AddressData a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_status
FROM 
    CombinedData
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 100;

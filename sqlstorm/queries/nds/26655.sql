
WITH CustomerNames AS (
    SELECT 
        c.c_customer_sk,
        TRIM(c.c_first_name) AS first_name,
        TRIM(c.c_last_name) AS last_name,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name
    FROM 
        customer c
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ' ', TRIM(ca.ca_street_type), 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca.ca_suite_number)) ELSE '' END) AS full_address,
        TRIM(ca.ca_city) AS city,
        TRIM(ca.ca_state) AS state,
        TRIM(ca.ca_zip) AS zip
    FROM 
        customer_address ca
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cn.full_name,
        ad.full_address,
        ad.city,
        ad.state,
        ad.zip,
        sd.total_sales,
        sd.order_count
    FROM 
        CustomerNames cn
    JOIN 
        customer c ON cn.c_customer_sk = c.c_customer_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesData sd ON cn.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    city,
    state,
    zip,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count
FROM 
    CombinedData
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC, full_name;

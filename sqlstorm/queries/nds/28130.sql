
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
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        a.full_address, 
        a.ca_city, 
        a.ca_state, 
        a.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS num_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.full_address,
    ci.ca_city, 
    ci.ca_state, 
    ci.ca_zip,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.num_orders, 0) AS num_orders
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ci.ca_state = 'CA' 
    AND ci.cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 50;

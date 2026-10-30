
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerMetrics AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.full_address,
        cd.ca_city,
        cd.ca_state,
        cd.ca_zip,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cm.full_name,
    cm.cd_gender,
    cm.cd_marital_status,
    cm.cd_education_status,
    cm.full_address,
    cm.ca_city,
    cm.ca_state,
    cm.ca_zip,
    cm.total_sales,
    cm.total_orders
FROM 
    CustomerMetrics cm
WHERE 
    cm.total_sales > 1000
ORDER BY 
    cm.total_sales DESC;

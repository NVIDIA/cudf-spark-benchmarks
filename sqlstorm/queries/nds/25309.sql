
WITH AddressComponents AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
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
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        ac.full_address,
        ac.ca_city,
        ac.ca_state,
        ac.ca_zip,
        ac.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN 
        AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name, 
    ci.gender, 
    ci.first_purchase_date, 
    sd.total_sales, 
    sd.total_orders,
    CONCAT(ci.ca_city, ', ', ci.ca_state, ' ', ci.ca_zip, ', ', ci.ca_country) AS full_location
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesDetails sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC;

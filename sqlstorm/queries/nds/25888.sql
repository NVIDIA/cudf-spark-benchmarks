
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ad.full_address,
        c.c_current_addr_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_orders, 0) AS total_orders,
    ca.ca_city,
    ca.ca_state
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData s ON ci.c_customer_sk = s.ws_bill_customer_sk
JOIN 
    customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
WHERE 
    UPPER(ci.cd_gender) = 'F' 
AND 
    ci.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC
LIMIT 100;

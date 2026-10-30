
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
        cd.cd_purchase_estimate,
        ADDR.full_address,
        ADDR.ca_city,
        ADDR.ca_state,
        ADDR.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ADDR ON c.c_current_addr_sk = ADDR.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws 
    JOIN 
        CustomerDetails cs ON ws.ws_bill_customer_sk = cs.c_customer_sk
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.cd_purchase_estimate,
    s.total_sales,
    s.total_orders,
    cs.full_address,
    cs.ca_city,
    cs.ca_state,
    cs.ca_zip
FROM 
    CustomerDetails cs
LEFT JOIN 
    SalesData s ON cs.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    cs.cd_marital_status = 'M' 
    AND cs.cd_purchase_estimate > 500 
    AND cs.cd_gender = 'F'
ORDER BY 
    COALESCE(s.total_sales, 0) DESC
LIMIT 100;


WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city, 
        ca_state, 
        ca_country 
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender, 
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
)
SELECT 
    cust.full_name,
    addr.full_address,
    s.total_quantity_sold,
    s.total_sales_amount
FROM 
    CustomerDetails cust
JOIN 
    AddressDetails addr ON cust.c_customer_sk = addr.ca_address_sk
JOIN 
    SalesDetails s ON cust.c_customer_sk = s.ws_item_sk
WHERE 
    cust.cd_gender = 'F'
    AND cust.cd_marital_status = 'M'
    AND s.total_sales_amount > 1000
ORDER BY 
    s.total_sales_amount DESC
LIMIT 100;


WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', COALESCE(ca_suite_number, ''), ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender, 
        cd_marital_status, 
        cd_purchase_estimate, 
        cd_credit_rating
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    a.full_address,
    COALESCE(s.total_sales, 0) AS total_sales
FROM 
    CustomerDetails c
JOIN 
    AddressDetails a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    SalesDetails s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    c.cd_gender = 'F' AND 
    c.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;

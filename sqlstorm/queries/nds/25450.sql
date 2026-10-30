
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), CustomerDetails AS (
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
), SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    AD.full_address,
    CD.full_name,
    CD.cd_gender,
    CD.cd_marital_status,
    COALESCE(SD.total_sales, 0) AS total_sales
FROM 
    AddressDetails AD
JOIN 
    CustomerDetails CD ON AD.ca_address_sk = CD.c_customer_sk
LEFT JOIN 
    SalesDetails SD ON CD.c_customer_sk = SD.ws_bill_customer_sk
WHERE 
    COALESCE(SD.total_sales, 0) > 1000
ORDER BY 
    total_sales DESC, AD.ca_city, AD.ca_state;

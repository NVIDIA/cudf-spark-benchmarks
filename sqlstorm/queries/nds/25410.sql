
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        c.c_current_addr_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
GenderPurchases AS (
    SELECT 
        cd.cd_gender,
        SUM(sd.total_sales) AS total_sales_by_gender
    FROM 
        CustomerDetails cd
    JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(gp.total_sales_by_gender, 0) AS total_sales_by_gender
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN 
    GenderPurchases gp ON cd.cd_gender = gp.cd_gender
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    cd.cd_purchase_estimate DESC;

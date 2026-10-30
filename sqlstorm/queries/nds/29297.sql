
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS complete_address,
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
        cd.cd_credit_rating,
        ad.complete_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_estimate_band,
        ad.ca_city,
        ad.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    JOIN 
        customer_address ad ON cd.complete_address = CONCAT(ad.ca_street_number, ' ', ad.ca_street_name, ' ', ad.ca_street_type)
)
SELECT 
    sd.full_name,
    sd.ws_order_number,
    sd.ws_item_sk,
    sd.ws_quantity,
    sd.ws_sales_price,
    sd.purchase_estimate_band,
    sd.ca_city,
    sd.ca_state,
    COUNT(*) OVER (PARTITION BY sd.purchase_estimate_band ORDER BY sd.ws_order_number) AS order_count
FROM 
    SalesData sd
WHERE 
    sd.cd_gender = 'F'
    AND sd.cd_marital_status = 'M'
ORDER BY 
    sd.purchase_estimate_band, 
    sd.full_name;

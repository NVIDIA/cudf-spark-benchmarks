
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
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
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUBSTRING(CAST(ws.ws_bill_customer_sk AS STRING), 1, 10) AS cust_id_part
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sales_price, ws.ws_quantity, SUBSTRING(CAST(ws.ws_bill_customer_sk AS STRING), 1, 10)
)
SELECT 
    ad.full_address,
    COUNT(DISTINCT cd.full_name) AS customer_count,
    SUM(sd.total_sales) AS total_sales
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON ad.ca_address_sk = cd.c_customer_sk 
JOIN 
    SalesData sd ON sd.cust_id_part = SUBSTRING(CAST(cd.c_customer_sk AS STRING), 1, 10) 
WHERE 
    ad.ca_state = 'CA' 
GROUP BY 
    ad.full_address
ORDER BY 
    total_sales DESC
LIMIT 10;

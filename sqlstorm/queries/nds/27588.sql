
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
AggregatedSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
StringPerformance AS (
    SELECT 
        cds.full_name,
        ads.full_address,
        ads.ca_city,
        ads.ca_state,
        ads.ca_zip,
        agg.total_orders,
        agg.total_sales,
        LENGTH(cds.full_name) AS full_name_length, 
        LENGTH(ads.full_address) AS address_length
    FROM 
        CustomerDetails cds
    JOIN 
        AddressDetails ads ON cds.c_customer_sk = ads.ca_address_sk
    JOIN 
        AggregatedSales agg ON cds.c_customer_sk = agg.ws_bill_customer_sk
)
SELECT 
    *
FROM 
    StringPerformance 
WHERE 
    total_orders > 2 
ORDER BY 
    total_sales DESC;


WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
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
        c_current_addr_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesOverview AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ad.full_address,
    ad.ca_zip,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    so.total_sales,
    so.order_count,
    so.unique_items
FROM 
    CustomerDetails cd
JOIN 
    SalesOverview so ON cd.c_customer_sk = so.ws_bill_customer_sk
JOIN 
    AddressDetails ad ON cd.c_current_addr_sk = ad.ca_address_sk
WHERE 
    cd.cd_purchase_estimate > 500
    AND ad.ca_city IS NOT NULL
ORDER BY 
    so.total_sales DESC
LIMIT 100;

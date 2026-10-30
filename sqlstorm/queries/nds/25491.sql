
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) || 
        CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
             THEN ' Ste ' || TRIM(ca_suite_number) ELSE '' END AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        TRIM(c.c_salutation) || ' ' || TRIM(c.c_first_name) || ' ' || TRIM(c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SaleDetails AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.full_name,
        cd.ca_city AS city,
        cd.ca_state AS state,
        cd.ca_zip AS zip
    FROM
        web_sales ws
    JOIN
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT 
    sd.full_name,
    sd.city,
    sd.state,
    sd.zip,
    SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
    COUNT(sd.ws_item_sk) AS total_items_sold
FROM 
    SaleDetails sd
GROUP BY 
    sd.full_name, sd.city, sd.state, sd.zip
HAVING 
    SUM(sd.ws_sales_price * sd.ws_quantity) > 1000
ORDER BY 
    total_sales DESC;


WITH AddressExtraction AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT 
    ae.full_address,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    sd.total_sales,
    sd.total_quantity,
    DENSE_RANK() OVER (PARTITION BY ae.ca_state ORDER BY sd.total_sales DESC) AS sales_rank
FROM AddressExtraction ae
JOIN CustomerInfo ci ON ci.c_customer_sk = ae.ca_address_sk
JOIN SalesData sd ON sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_desc ILIKE '%gadget%')
WHERE ae.ca_country = 'USA' 
AND ci.cd_marital_status = 'M'
ORDER BY sales_rank, total_sales DESC;


WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM customer_address
),
DemographicDetails AS (
    SELECT 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_demo_sk
    FROM customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ad.full_address,
        dd.gender,
        dd.cd_marital_status,
        dd.cd_education_status
    FROM customer c
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN DemographicDetails dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN ws_bill_customer_sk IS NOT NULL THEN 'Web Sale'
            WHEN cs_bill_customer_sk IS NOT NULL THEN 'Catalog Sale'
            ELSE 'Store Sale'
        END AS sale_type,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(cs_sales_price) AS total_catalog_sales_price,
        SUM(ss_sales_price) AS total_store_sales_price
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    GROUP BY 
        CASE 
            WHEN ws_bill_customer_sk IS NOT NULL THEN 'Web Sale'
            WHEN cs_bill_customer_sk IS NOT NULL THEN 'Catalog Sale'
            ELSE 'Store Sale'
        END
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ss.sale_type,
    ss.total_sales_price,
    ss.total_catalog_sales_price,
    ss.total_store_sales_price
FROM CustomerDetails cd
JOIN SalesSummary ss ON ss.sale_type IS NOT NULL
JOIN AddressDetails ad ON cd.full_address = ad.full_address
WHERE cd.c_email_address LIKE '%@example.com'
ORDER BY cd.c_last_name, cd.c_first_name;

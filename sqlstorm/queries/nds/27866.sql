
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),

CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        TRIM(c.c_first_name) || ' ' || TRIM(c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
),

SalesSummary AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN CustomerDetails c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)

SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    ss.total_sales,
    ss.order_count,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    cd.ca_country
FROM CustomerDetails cd
LEFT JOIN SalesSummary ss ON cd.c_customer_sk = ss.customer_sk
ORDER BY ss.total_sales DESC, cd.full_name ASC
LIMIT 100;

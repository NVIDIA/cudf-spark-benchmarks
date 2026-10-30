
WITH AddressProcessing AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS lowered_city,
        TRIM(ca_state) AS trimmed_state,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.lowered_city,
        ad.trimmed_state,
        ad.zip_prefix
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressProcessing ad ON c.c_current_addr_sk = ad.ca_address_sk
),
PurchaseAnalytics AS (
    SELECT 
        cd.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_spent
    FROM web_sales ws
    JOIN CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY cd.c_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    pa.total_orders,
    pa.total_quantity,
    pa.total_spent,
    cd.lowered_city,
    CONCAT(cd.trimmed_state, ' ', cd.zip_prefix) AS state_zip_combined
FROM CustomerDetails cd
JOIN PurchaseAnalytics pa ON cd.c_customer_sk = pa.c_customer_sk
ORDER BY pa.total_spent DESC
LIMIT 100;

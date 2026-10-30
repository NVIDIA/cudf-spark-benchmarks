
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sd.total_sales) AS total_spent,
    COUNT(sd.order_count) AS total_orders,
    ap.full_address,
    ap.ca_city,
    ap.ca_state,
    ap.ca_zip
FROM CustomerDetails cd
JOIN store_returns sr ON cd.c_customer_sk = sr.sr_customer_sk
JOIN AddressParts ap ON sr.sr_addr_sk = ap.ca_address_sk
JOIN SalesData sd ON sr.sr_item_sk = sd.ws_item_sk
WHERE cd.cd_purchase_estimate > 1000
GROUP BY 
    cd.full_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    ap.full_address, 
    ap.ca_city, 
    ap.ca_state, 
    ap.ca_zip
ORDER BY total_spent DESC;

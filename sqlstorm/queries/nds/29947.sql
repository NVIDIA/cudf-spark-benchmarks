
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        d.d_year AS birth_year,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        ab.full_address,
        ab.ca_city,
        ab.ca_state,
        ab.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ab ON c.c_current_addr_sk = ab.ca_address_sk
    LEFT JOIN date_dim d ON d.d_date_sk = c.c_birth_day
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    ci.gender,
    si.total_profit,
    si.total_orders,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip
FROM CustomerInfo ci
JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE si.total_profit > 1000 
AND ci.birth_year >= (EXTRACT(YEAR FROM CURRENT_DATE) - 25)
ORDER BY si.total_profit DESC;


WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        REPLACE(ca_zip, '-', '') AS clean_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        CAST(CONCAT(c_birth_month, '/', c_birth_day, '/', c_birth_year) AS DATE) AS birth_date
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesAggregates AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_paid,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)

SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.clean_zip,
    a.ca_country,
    s.total_quantity,
    s.total_paid,
    s.order_count,
    DENSE_RANK() OVER (ORDER BY s.total_paid DESC) AS payment_rank
FROM CustomerDetails c
JOIN AddressDetails a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN SalesAggregates s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE a.ca_state = 'CA'
AND s.total_paid > 100
ORDER BY s.total_paid DESC, c.full_name ASC
LIMIT 100;

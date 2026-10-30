
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date = (
        SELECT MAX(d2.d_date)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
    )
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        c.c_customer_sk
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
summary AS (
    SELECT 
        cd.full_name,
        cd.last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country
    FROM customer_data cd
    JOIN address_summary a ON cd.c_customer_sk = a.c_customer_sk
)
SELECT 
    full_name,
    last_purchase_date,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    LENGTH(full_name) AS name_length,
    UPPER(full_name) AS upper_full_name,
    CONCAT_WS(', ', ca_city, ca_state, ca_zip) AS city_state_zip,
    CONCAT(cd_gender, ' - ', cd_marital_status) AS gender_marital_status,
    SUBSTRING(cd_education_status, 1, 10) AS short_education_status
FROM summary
ORDER BY last_purchase_date DESC
LIMIT 100;

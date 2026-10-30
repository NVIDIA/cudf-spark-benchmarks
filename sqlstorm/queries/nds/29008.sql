
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(COALESCE(ca_street_number, ''), ' ', COALESCE(ca_street_name, ''), ' ', COALESCE(ca_street_type, ''))) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper,
        REPLACE(ca_zip, '-', '') AS clean_zip
    FROM customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        processed.full_address,
        processed.city_lower,
        processed.state_upper,
        processed.clean_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN processed_addresses processed ON c.c_current_addr_sk = processed.ca_address_sk
),
date_info AS (
    SELECT 
        d.d_date_sk,
        d.d_day_name,
        d.d_month_seq,
        d.d_year,
        CONCAT(d.d_day_name, ', ', d.d_month_seq, ' ', d.d_year) AS formatted_date
    FROM date_dim d
),
sales_data AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.full_address,
    ci.city_lower,
    ci.state_upper,
    ci.clean_zip,
    di.formatted_date,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_transactions, 0) AS total_transactions
FROM customer_info ci
JOIN date_info di ON di.d_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d)
LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ss_customer_sk
ORDER BY ci.full_name;

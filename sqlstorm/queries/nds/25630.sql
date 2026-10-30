
WITH  date_range AS (
    SELECT d_date_sk, d_date, EXTRACT(YEAR FROM d_date) AS d_year
    FROM date_dim
    WHERE d_date >= '2023-01-01' AND d_date < '2024-01-01'
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
address_summary AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_address_sk, ca_city, ca_state
)
SELECT
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ss.total_quantity,
    ss.total_sales,
    ss.total_orders,
    dr.d_year,
    address.ca_city,
    address.ca_state,
    address.address_count
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
JOIN date_range dr ON dr.d_year = ci.cd_purchase_estimate
JOIN address_summary address ON ci.c_customer_sk = address.ca_address_sk
WHERE ci.cd_gender = 'F'
AND ci.cd_marital_status = 'M'
AND dr.d_year IN (2023, 2024)
ORDER BY ss.total_sales DESC, ci.full_name ASC
LIMIT 100;

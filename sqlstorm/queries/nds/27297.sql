
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city AS city,
        UPPER(ca_state) AS state_upper,
        LEFT(ca_zip, 5) AS zip_prefix
    FROM
        customer_address
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.full_address,
        ca.city
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        c.full_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM
        store_sales ss
    JOIN customer_details c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY
        c.full_name
)
SELECT
    cs.full_name,
    cs.total_quantity,
    cs.total_net_paid,
    CASE 
        WHEN cs.total_net_paid > 500 THEN 'High Value'
        WHEN cs.total_net_paid BETWEEN 200 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM
    sales_summary cs
WHERE
    cs.total_quantity > 0
ORDER BY
    cs.total_net_paid DESC;

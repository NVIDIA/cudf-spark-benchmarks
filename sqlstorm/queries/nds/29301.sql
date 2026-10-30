
WITH AddressComponents AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        d.d_year,
        d.d_month_seq,
        dc.cd_gender,
        dc.cd_marital_status,
        dc.cd_purchase_estimate
    FROM
        customer c
    JOIN customer_demographics dc ON c.c_current_cdemo_sk = dc.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesSummary AS (
    SELECT
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_purchases,
        AVG(ss.ss_net_paid) AS avg_purchase_value
    FROM
        store_sales ss
    JOIN CustomerInfo c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    ci.full_name,
    ci.c_email_address,
    ci.d_year,
    ci.d_month_seq,
    ac.full_address,
    ac.city_state_zip,
    ss.total_spent,
    ss.total_purchases,
    ss.avg_purchase_value
FROM
    CustomerInfo ci
JOIN AddressComponents ac ON ci.c_customer_sk = ac.ca_address_sk
JOIN SalesSummary ss ON ci.c_customer_sk = ss.c_customer_sk
ORDER BY
    ss.total_spent DESC
LIMIT 100;

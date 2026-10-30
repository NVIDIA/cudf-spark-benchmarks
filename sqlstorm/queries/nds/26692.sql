
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_estimate_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ss.ss_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.purchase_estimate_category,
    ad.full_address,
    s.total_spent,
    s.total_transactions
FROM CustomerDetails cd
JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN SalesData s ON cd.c_customer_sk = s.ss_customer_sk
WHERE s.total_spent > 500
ORDER BY s.total_spent DESC, cd.full_name;

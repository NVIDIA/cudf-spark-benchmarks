
WITH AddressFull AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE 
                   WHEN ca.ca_suite_number IS NOT NULL AND ca.ca_suite_number <> '' 
                   THEN CONCAT(' Suite ', ca.ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM
        customer_address ca
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ad.full_address
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressFull ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesInfo AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.full_address,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.order_count, 0) AS order_count
    FROM
        CustomerInfo ci
    LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)

SELECT
    fb.c_customer_sk,
    fb.c_first_name,
    fb.c_last_name,
    fb.cd_gender,
    fb.cd_marital_status,
    fb.cd_purchase_estimate,
    fb.cd_credit_rating,
    fb.full_address,
    fb.total_sales,
    fb.order_count,
    ROW_NUMBER() OVER (ORDER BY fb.total_sales DESC) AS sales_rank
FROM
    FinalBenchmark fb
WHERE
    fb.total_sales > 0
ORDER BY
    fb.total_sales DESC;

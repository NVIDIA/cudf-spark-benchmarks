
WITH AddressAnalysis AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_county,
        ca_state,
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_country) AS country_upper,
        REGEXP_REPLACE(ca_street_name, 'St|Ave|Blvd', '') AS cleaned_street_name,
        TRIM(ca_street_type) AS trimmed_street_type
    FROM
        customer_address
),
CustomerAnalysis AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        LTRIM(RTRIM(c_email_address)) AS cleaned_email
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesAnalysis AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_ship_addr_sk) AS unique_ship_addresses
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
    COUNT(DISTINCT ca.ca_zip) AS unique_zips,
    SUM(cs.total_sales) AS total_sales,
    SUM(cs.order_count) AS total_orders,
    COUNT(DISTINCT c.full_name) AS unique_customers,
    AVG(c.cd_purchase_estimate) AS avg_purchase_estimate
FROM
    AddressAnalysis ca
LEFT JOIN
    CustomerAnalysis c ON ca.ca_address_sk = c.c_customer_sk
LEFT JOIN
    SalesAnalysis cs ON c.c_customer_sk = cs.ws_bill_customer_sk
WHERE
    ca.ca_state = 'CA'
GROUP BY
    ca.ca_city
ORDER BY
    total_sales DESC
LIMIT 10;

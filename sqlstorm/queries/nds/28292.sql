
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        LEFT(ca_zip, 5) AS zip_code_prefix
    FROM
        customer_address
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS demographic_profile
    FROM
        customer_demographics
),
CustomerDetails AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        cd.demographic_profile,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.zip_code_prefix
    FROM
        customer c
    JOIN
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        AddressDetails addr ON c.c_current_addr_sk = addr.ca_address_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    cust.full_name,
    cust.c_email_address,
    cust.demographic_profile,
    cust.full_address,
    cust.ca_city,
    cust.ca_state,
    sales.total_sales,
    sales.total_orders
FROM
    CustomerDetails cust
LEFT JOIN
    SalesData sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
WHERE
    cust.ca_city LIKE 'San%'
ORDER BY
    sales.total_sales DESC
LIMIT 10;

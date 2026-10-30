
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT
        cd.full_name,
        cd.c_birth_day,
        cd.c_birth_month,
        cd.c_birth_year,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        sd.total_sales,
        sd.order_count
    FROM
        CustomerDetails cd
    LEFT JOIN
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        ELSE 'Total Sales: ' || total_sales
    END AS sales_status,
    CONCAT(c_birth_day, '-', c_birth_month, '-', c_birth_year) AS birth_date_formatted
FROM
    CustomerSales
WHERE
    ca_state = 'CA' AND
    order_count > 5
ORDER BY
    total_sales DESC
LIMIT 100;


WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),

CustomerDetails AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM
        customer
    JOIN
        customer_demographics ON c_customer_sk = c_current_cdemo_sk
),

SalesOverview AS (
    SELECT
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ws_bill_customer_sk,
        ws_ship_addr_sk
    FROM
        web_sales
    WHERE
        ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_ship_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_ship_date_sk, ws_bill_customer_sk, ws_ship_addr_sk
)

SELECT
    d.d_date AS sales_date,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    a.full_address,
    s.total_quantity,
    s.total_sales
FROM
    SalesOverview s
JOIN
    date_dim d ON s.ws_ship_date_sk = d.d_date_sk
JOIN
    CustomerDetails c ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN
    AddressDetails a ON s.ws_ship_addr_sk = a.ca_address_sk
WHERE
    s.total_sales > 1000
ORDER BY
    sales_date DESC, s.total_sales DESC
LIMIT 100;

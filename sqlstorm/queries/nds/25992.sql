
WITH CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TotalSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ts.total_sales
    FROM CustomerInfo ci
    JOIN TotalSales ts ON ci.c_customer_sk = ts.ws_bill_customer_sk
    ORDER BY ts.total_sales DESC
    LIMIT 10
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_country) AS full_location,
    total_sales
FROM TopCustomers;

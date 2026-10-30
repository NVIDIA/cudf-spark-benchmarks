
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        UPPER(ca_city) AS city_upper,
        ca_state,
        ca_zip
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        A.full_address,
        A.city_upper,
        A.ca_state,
        A.ca_zip
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails A ON c.c_current_addr_sk = A.ca_address_sk
),
SalesDetail AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MIN(ws_sold_date_sk) AS first_order_date,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT
        C.full_name,
        C.cd_gender,
        C.cd_marital_status,
        C.cd_education_status,
        S.total_sales,
        S.order_count,
        S.first_order_date,
        S.last_order_date,
        C.city_upper,
        C.ca_state,
        C.ca_zip
    FROM
        CustomerDetails C
    LEFT JOIN SalesDetail S ON C.c_customer_sk = S.ws_bill_customer_sk
)
SELECT
    city_upper,
    ca_state,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales,
    COUNT(DISTINCT first_order_date) AS unique_first_order_dates,
    COUNT(DISTINCT last_order_date) AS unique_last_order_dates
FROM
    FinalReport
GROUP BY
    city_upper, ca_state
ORDER BY
    customer_count DESC, avg_sales DESC;

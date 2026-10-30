
WITH AddressComponents AS (
    SELECT
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM
        customer_address
),
Demographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM
        customer_demographics
    GROUP BY
        cd_gender,
        cd_marital_status,
        cd_education_status
),
DailySales AS (
    SELECT
        d_year,
        d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY
        d_year,
        d_month_seq
)
SELECT
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.full_address,
    a.address_length,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.demographic_count,
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    s.order_count
FROM
    AddressComponents a
JOIN
    Demographics d ON a.ca_city LIKE CONCAT('%', d.cd_gender, '%') OR a.ca_state LIKE CONCAT('%', d.cd_marital_status, '%')
JOIN
    DailySales s ON a.address_length > 50
ORDER BY
    s.total_sales DESC,
    a.ca_city,
    d.cd_gender;

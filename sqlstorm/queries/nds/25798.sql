
WITH Address_Parsing AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_street_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM
        customer_address
),
Customer_Summary AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.full_street_address,
        ad.city,
        ad.state,
        ad.zip
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        Address_Parsing ad ON c.c_current_addr_sk = ad.ca_address_sk
),
Sales_Stats AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
Benchmark AS (
    SELECT
        cs.c_customer_sk,
        cs.customer_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        ss.total_sales,
        ss.order_count,
        LENGTH(cs.full_street_address) AS address_length,
        CONCAT(cs.city, ', ', cs.state, ' ', cs.zip) AS full_location
    FROM
        Customer_Summary cs
    LEFT JOIN
        Sales_Stats ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT
    *,
    CASE
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales > 1000 THEN 'High Roller'
        ELSE 'Average Customer'
    END AS customer_status
FROM
    Benchmark
ORDER BY
    total_sales DESC, address_length ASC;

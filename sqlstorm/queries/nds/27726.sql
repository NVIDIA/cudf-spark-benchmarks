
WITH AddressData AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM
        customer_address ca
),
CustomerData AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
CustomerPerformance AS (
    SELECT
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        sd.total_sales,
        sd.total_orders
    FROM
        CustomerData cd
    JOIN AddressData ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    cp.*,
    CAST(total_sales AS DECIMAL) / NULLIF(total_orders, 0) AS avg_sale_per_order,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    CustomerPerformance cp
ORDER BY
    total_sales DESC
LIMIT 100;

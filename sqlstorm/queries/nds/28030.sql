
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_count,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_demo_sk
),
DateRange AS (
    SELECT 
        MIN(d_date) AS min_date,
        MAX(d_date) AS max_date
    FROM date_dim
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_date BETWEEN (SELECT min_date FROM DateRange) AND (SELECT max_date FROM DateRange))
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date BETWEEN (SELECT min_date FROM DateRange) AND (SELECT max_date FROM DateRange))
    GROUP BY ws_bill_customer_sk
)
SELECT 
    a.ca_address_sk,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    d.male_count,
    d.female_count,
    d.avg_purchase_estimate,
    s.total_sales,
    s.total_orders
FROM AddressParts a
LEFT JOIN Demographics d ON a.ca_address_sk = d.cd_demo_sk
LEFT JOIN SalesData s ON a.ca_address_sk = s.ws_bill_customer_sk
ORDER BY a.ca_city, a.ca_state;

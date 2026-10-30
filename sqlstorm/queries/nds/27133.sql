
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerCount AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
SalesData AS (
    SELECT 
        EXTRACT(YEAR FROM d_date) AS sales_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY EXTRACT(YEAR FROM d_date)
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.max_street_name_length,
    a.min_street_name_length,
    a.avg_street_name_length,
    c.cd_gender,
    c.total_customers,
    s.sales_year,
    s.total_sales,
    s.total_orders
FROM AddressStats a
JOIN CustomerCount c ON a.total_addresses > 1000
JOIN SalesData s ON s.total_sales > 1000000
ORDER BY a.ca_state, c.cd_gender, s.sales_year DESC;

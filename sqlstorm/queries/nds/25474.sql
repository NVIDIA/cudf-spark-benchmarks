
WITH AddressStats AS (
    SELECT
        ca_county,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_length,
        MIN(LENGTH(ca_street_name)) AS min_street_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_length
    FROM customer_address
    GROUP BY ca_county
),
CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_id) AS unique_customers
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
DateStats AS (
    SELECT
        d_year,
        COUNT(*) AS sales_count,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_sale_price
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
)
SELECT 
    a.ca_county,
    a.address_count,
    a.max_street_length,
    a.min_street_length,
    a.avg_street_length,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.unique_customers,
    d.d_year,
    d.sales_count,
    d.total_sales,
    d.avg_sale_price
FROM AddressStats a
JOIN CustomerStats c ON a.address_count > 100
JOIN DateStats d ON d.sales_count > 50
ORDER BY a.ca_county, c.cd_gender, d.d_year;

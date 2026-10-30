
WITH address_stats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip
    FROM
        customer_address
    GROUP BY
        ca_state
),
demographics_stats AS (
    SELECT
        cd_gender,
        COUNT(*) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
sales_summary AS (
    SELECT
        d_year,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_sale,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY
        d_year
)
SELECT 
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.min_zip,
    a.max_zip,
    d.cd_gender,
    d.demo_count,
    d.avg_purchase_estimate,
    d.avg_dep_count,
    s.d_year,
    s.total_sales,
    s.avg_sale,
    s.order_count
FROM 
    address_stats a
JOIN 
    demographics_stats d ON a.address_count > 100
JOIN 
    sales_summary s ON s.total_sales > 1000000
ORDER BY 
    a.ca_state, d.cd_gender, s.d_year;

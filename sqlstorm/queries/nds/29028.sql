
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS city_uppercase,
        LENGTH(ca_zip) AS zip_length,
        REPLACE(REPLACE(ca_country, ' ', ''), '-', '') AS sanitized_country
    FROM
        customer_address
),
customer_stats AS (
    SELECT
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependencies,
        MAX(cd_purchase_estimate) AS max_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd_gender
),
date_stats AS (
    SELECT
        d_year,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY
        d_year
)
SELECT
    pa.full_address,
    pa.city_uppercase,
    pa.zip_length,
    cs.customer_count,
    cs.avg_dependencies,
    ds.total_orders,
    ds.total_profit
FROM
    processed_addresses pa
JOIN
    customer_stats cs ON cs.customer_count > 100
JOIN
    date_stats ds ON ds.total_profit > 1000
WHERE
    pa.sanitized_country = 'USA'
ORDER BY
    pa.full_address, cs.customer_count DESC;

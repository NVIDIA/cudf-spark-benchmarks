
WITH CustomerLocation AS (
    SELECT
        ca_state,
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_address
    JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY
        ca_state, ca_city
),
TopCities AS (
    SELECT
        ca_city,
        ca_state,
        customer_count,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY customer_count DESC) AS city_rank
    FROM
        CustomerLocation
),
DateRange AS (
    SELECT
        d_year,
        COUNT(DISTINCT ws_order_number) AS sales_count,
        SUM(ws_sales_price) AS total_sales
    FROM
        web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE
        d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY
        d_year
)
SELECT
    t.ca_city,
    t.ca_state,
    t.customer_count,
    dr.d_year,
    dr.sales_count,
    dr.total_sales
FROM
    TopCities t
JOIN DateRange dr ON t.city_rank = 1
WHERE
    t.customer_count > 100
ORDER BY
    t.ca_state, t.customer_count DESC, dr.total_sales DESC;

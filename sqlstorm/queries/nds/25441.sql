
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities,
        STRING_AGG(DISTINCT CONCAT(ca_street_name, ' ', ca_street_number, ' ', ca_street_type), '; ') AS full_address_list
    FROM
        customer_address
    GROUP BY
        ca_state
),
GenderStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS demo_count,
        AVG(cd_dep_count) AS avg_dependents,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
SalesData AS (
    SELECT
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CAST(ws_ship_mode_sk AS STRING), ', ') AS unique_shipping_modes
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY
        d_year
)
SELECT
    A.ca_state,
    A.address_count,
    A.unique_cities,
    A.full_address_list,
    G.cd_gender,
    G.demo_count,
    G.avg_dependents,
    G.education_levels,
    S.d_year,
    S.total_net_profit,
    S.order_count,
    S.unique_shipping_modes
FROM
    AddressStats A
JOIN
    GenderStats G ON A.address_count > 100  
JOIN
    SalesData S ON S.total_net_profit > 1000  
ORDER BY
    A.ca_state, G.cd_gender, S.d_year;

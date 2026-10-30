
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_dep_count) AS max_dependents,
        MIN(cd_dep_count) AS min_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_gender
),
SalesStats AS (
    SELECT
        ds.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit,
        MAX(ws_net_profit) AS max_net_profit,
        MIN(ws_net_profit) AS min_net_profit
    FROM web_sales
    JOIN date_dim ds ON ws_sold_date_sk = ds.d_date_sk
    GROUP BY ds.d_year
)
SELECT
    a.ca_state,
    a.unique_addresses,
    a.total_addresses,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.avg_dependents,
    c.max_dependents,
    c.min_dependents,
    c.avg_purchase_estimate,
    c.max_purchase_estimate,
    c.min_purchase_estimate,
    s.d_year,
    s.total_sales,
    s.total_coupons,
    s.total_orders,
    s.avg_net_profit,
    s.max_net_profit,
    s.min_net_profit
FROM AddressStats a
JOIN CustomerStats c ON 1=1
JOIN SalesStats s ON 1=1
ORDER BY a.ca_state, c.cd_gender, s.d_year;

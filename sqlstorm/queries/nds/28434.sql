
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        SUM(CASE
            WHEN ca_city LIKE '%town%' THEN 1
            ELSE 0
        END) AS town_addresses,
        SUM(CASE
            WHEN ca_street_name LIKE '%Main%' THEN 1 
            ELSE 0 
        END) AS main_street_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM
        customer_address
    GROUP BY
        ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender
),
SalesStats AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
)
SELECT
    a.ca_state,
    a.address_count,
    a.town_addresses,
    a.main_street_addresses,
    a.avg_street_name_length,
    c.cd_gender,
    c.unique_customers,
    c.avg_purchase_estimate,
    c.max_dependents,
    s.total_sales,
    s.avg_net_profit,
    s.unique_orders
FROM
    AddressStats a
JOIN
    CustomerStats c ON a.address_count > 100
JOIN
    SalesStats s ON s.total_sales > 10000
ORDER BY
    a.ca_state, c.cd_gender;

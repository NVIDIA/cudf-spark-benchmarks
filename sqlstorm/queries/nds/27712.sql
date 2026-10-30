
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT ca_zip) AS unique_zips,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL
    GROUP BY 
        ca_state
), 
CustomerStats AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS customer_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), 
SalesStats AS (
    SELECT 
        'web' AS channel,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    UNION ALL
    SELECT 
        'store' AS channel,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_orders,
        AVG(ss_net_profit) AS avg_net_profit
    FROM 
        store_sales
), 
ItemStats AS (
    SELECT 
        i_category,
        COUNT(DISTINCT i_item_sk) AS total_items,
        SUM(i_current_price) AS total_value,
        AVG(i_current_price) AS avg_price
    FROM 
        item
    GROUP BY 
        i_category
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.unique_zips,
    a.avg_street_name_length,
    c.cd_gender,
    c.total_dependents,
    s.channel,
    s.total_sales,
    s.total_orders,
    s.avg_net_profit,
    i.i_category,
    i.total_items,
    i.total_value,
    i.avg_price
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON c.customer_count > 100
JOIN 
    SalesStats s ON s.total_sales > 10000
JOIN 
    ItemStats i ON i.avg_price < 50
ORDER BY 
    a.total_addresses DESC, 
    c.total_dependents DESC, 
    s.total_sales DESC;

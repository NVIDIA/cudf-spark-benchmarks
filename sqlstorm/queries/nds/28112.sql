
WITH AddressData AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
), 
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
), 
SalesStats AS (
    SELECT 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS most_recent_order_date
    FROM web_sales
), 
CombinedStats AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.full_address,
        ad.address_count,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.demographic_count,
        ss.total_net_profit,
        ss.total_orders,
        ss.most_recent_order_date
    FROM AddressData ad
    JOIN CustomerStats cs ON ad.ca_city = cs.cd_gender 
    CROSS JOIN SalesStats ss
)
SELECT 
    ca_city,
    ca_state,
    full_address,
    address_count,
    cd_gender,
    cd_marital_status,
    demographic_count,
    total_net_profit,
    total_orders,
    most_recent_order_date
FROM CombinedStats
WHERE address_count > 5 AND total_net_profit > 1000
ORDER BY total_net_profit DESC, address_count DESC
LIMIT 100;

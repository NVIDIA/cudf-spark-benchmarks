
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    GROUP BY ca_state
), DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
), SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), CombinedStats AS (
    SELECT 
        a.ca_state,
        d.cd_gender,
        s.total_net_profit,
        s.total_quantity_sold,
        a.address_count,
        d.demographic_count,
        a.avg_gmt_offset,
        d.avg_purchase_estimate
    FROM AddressStats a
    JOIN DemographicStats d ON a.address_count > d.demographic_count
    LEFT JOIN SalesStats s ON a.address_count = s.ws_bill_customer_sk
)
SELECT 
    ca_state,
    cd_gender,
    COUNT(*) AS num_records,
    SUM(total_net_profit) AS total_net_profit,
    SUM(total_quantity_sold) AS total_quantity_sold,
    AVG(avg_gmt_offset) AS avg_gmt_offset,
    AVG(avg_purchase_estimate) AS avg_purchase_estimate
FROM CombinedStats
GROUP BY ca_state, cd_gender, total_net_profit, total_quantity_sold, avg_gmt_offset, avg_purchase_estimate
ORDER BY total_net_profit DESC
LIMIT 10;


WITH AddressDetails AS (
    SELECT 
        ca_city, 
        ca_state, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_address_sk
    FROM 
        customer_address
), 
CustomerStatistics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.avg_purchase_estimate,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COUNT(DISTINCT ad.full_address) AS unique_addresses
FROM 
    CustomerStatistics cs
LEFT JOIN 
    SalesData sd ON cs.cd_demo_sk = sd.ws_bill_cdemo_sk
JOIN 
    AddressDetails ad ON cs.cd_demo_sk = ad.ca_address_sk
GROUP BY 
    cs.cd_gender, 
    cs.cd_marital_status, 
    cs.customer_count, 
    cs.avg_purchase_estimate, 
    sd.total_profit, 
    sd.total_orders
ORDER BY 
    cs.customer_count DESC
LIMIT 100;


WITH demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS total_married,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS total_single,
        SUM(CASE WHEN cd_credit_rating = 'Excellent' THEN 1 ELSE 0 END) AS total_excellent_credit,
        cd_demo_sk
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_demo_sk
),
location_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_address_id, ', ') AS address_ids
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ds.cd_gender,
    ds.total_customers,
    ds.avg_purchase_estimate,
    ds.total_married,
    ds.total_single,
    ds.total_excellent_credit,
    ls.ca_state,
    ls.total_addresses,
    ls.address_ids,
    ss.total_quantity_sold,
    ss.total_net_profit
FROM 
    demographic_summary ds
JOIN 
    location_summary ls ON ds.cd_gender = CASE WHEN ls.total_addresses < 100 THEN 'F' ELSE 'M' END
LEFT JOIN 
    sales_summary ss ON ds.cd_demo_sk = ss.ws_bill_cdemo_sk
ORDER BY 
    ds.total_customers DESC, ss.total_net_profit DESC
LIMIT 50;

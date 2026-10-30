
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(CAST(SUBSTRING(ca_zip FROM 1 FOR 5) AS INTEGER)) AS max_zip5,
        MIN(CAST(SUBSTRING(ca_zip FROM 1 FOR 5) AS INTEGER)) AS min_zip5
    FROM 
        customer_address
    GROUP BY 
        ca_state
), CustomerDemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dep_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), TopItems AS (
    SELECT 
        i_item_id,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_item_id
    ORDER BY 
        total_profit DESC
    LIMIT 10
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.avg_street_name_length,
    A.max_zip5,
    A.min_zip5,
    C.cd_gender,
    C.total_customers,
    C.avg_dep_count,
    C.avg_purchase_estimate,
    T.i_item_id,
    T.total_profit
FROM 
    AddressStats A
JOIN 
    CustomerDemographicsStats C ON A.total_addresses > 100
CROSS JOIN 
    TopItems T
ORDER BY 
    A.ca_state, C.cd_gender, T.total_profit DESC;


WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStatistics AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
ReturnStatistics AS (
    SELECT 
        sr_reason_sk,
        COUNT(sr_item_sk) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_reason_sk
)
SELECT 
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    r.return_count,
    r.total_return_amount,
    r.avg_return_quantity
FROM 
    AddressStatistics a
JOIN 
    CustomerStatistics c ON 1=1
JOIN 
    ReturnStatistics r ON a.ca_state IS NOT NULL
ORDER BY 
    a.ca_state, c.cd_gender;

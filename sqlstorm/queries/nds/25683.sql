
WITH AddressSummary AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses, 
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_street_type LIKE '%Ave%' THEN 1 ELSE 0 END) AS ave_count,
        SUM(CASE WHEN ca_street_type LIKE '%St%' THEN 1 ELSE 0 END) AS st_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS demographic_count, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
ItemDescription AS (
    SELECT 
        i_category, 
        COUNT(*) AS item_count, 
        MIN(LENGTH(i_item_desc)) AS min_item_desc_length, 
        MAX(LENGTH(i_item_desc)) AS max_item_desc_length
    FROM 
        item
    GROUP BY 
        i_category
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.avg_street_name_length,
    a.ave_count,
    a.st_count,
    c.cd_gender,
    c.demographic_count,
    c.avg_purchase_estimate,
    i.i_category,
    i.item_count,
    i.min_item_desc_length,
    i.max_item_desc_length
FROM 
    AddressSummary a
JOIN 
    CustomerDemographics c ON a.unique_addresses > 0
JOIN 
    ItemDescription i ON a.unique_addresses < 1000
ORDER BY 
    a.ca_state, c.cd_gender, i.i_category;


WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(ca_address_sk) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demographics_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS total_dependents_employed
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
ItemDescriptions AS (
    SELECT 
        LOWER(i_item_desc) AS item_desc_lower,
        COUNT(i_item_sk) AS item_count,
        SUM(i_current_price) AS total_price,
        AVG(i_current_price) AS avg_price
    FROM 
        item
    GROUP BY 
        LOWER(i_item_desc)
),
FinalBenchmark AS (
    SELECT 
        ac.ca_city,
        ac.address_count,
        ac.max_street_name_length,
        ac.min_street_name_length,
        ac.avg_street_name_length,
        de.cd_gender,
        de.demographics_count,
        de.avg_purchase_estimate,
        de.total_dependents,
        de.total_dependents_employed,
        id.item_desc_lower,
        id.item_count,
        id.total_price,
        id.avg_price
    FROM 
        AddressCounts ac
    LEFT JOIN 
        Demographics de ON ac.address_count > 100
    LEFT JOIN 
        ItemDescriptions id ON LENGTH(id.item_desc_lower) < 50
)
SELECT 
    ca_city,
    address_count,
    max_street_name_length,
    min_street_name_length,
    avg_street_name_length,
    cd_gender,
    demographics_count,
    avg_purchase_estimate,
    total_dependents,
    total_dependents_employed,
    item_desc_lower,
    item_count,
    total_price,
    avg_price
FROM 
    FinalBenchmark
ORDER BY 
    address_count DESC, demographics_count DESC;

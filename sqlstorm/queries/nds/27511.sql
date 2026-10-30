
WITH Address_Analytics AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_city LIKE 'A%' THEN 1 ELSE 0 END) AS cities_starting_with_A
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
Customer_Demo AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), 
Item_Details AS (
    SELECT 
        i_brand,
        COUNT(*) AS total_items,
        SUM(i_current_price) AS total_value,
        AVG(LENGTH(i_item_desc)) AS avg_description_length
    FROM 
        item
    GROUP BY 
        i_brand
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.avg_street_name_length,
    a.cities_starting_with_A,
    c.cd_gender,
    c.total_customers,
    c.total_dependents,
    c.avg_purchase_estimate,
    i.i_brand,
    i.total_items,
    i.total_value,
    i.avg_description_length
FROM 
    Address_Analytics a
JOIN 
    Customer_Demo c ON a.ca_state IN (SELECT DISTINCT ca_state FROM customer_address)
JOIN 
    Item_Details i ON i.total_items > 0
ORDER BY 
    a.ca_state, c.cd_gender, i.i_brand;

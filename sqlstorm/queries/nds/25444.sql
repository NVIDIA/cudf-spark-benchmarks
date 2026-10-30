
WITH customer_address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS unique_street_descriptions
    FROM customer_address
    GROUP BY ca_state
),
demographics_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
item_sales_summary AS (
    SELECT 
        i_item_id,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_net_paid) AS total_sales,
        AVG(cs_sales_price) AS avg_sales_price
    FROM catalog_sales
    JOIN item ON cs_item_sk = i_item_sk
    GROUP BY i_item_id
)
SELECT 
    c.ca_state AS state,
    c.unique_addresses AS total_unique_addresses,
    d.cd_gender AS gender,
    d.cd_marital_status AS marital_status,
    d.demographic_count AS total_demographics,
    i.total_quantity_sold AS item_quantity_sold,
    i.total_sales AS item_sales_value
FROM customer_address_summary c
JOIN demographics_summary d ON c.ca_state = d.cd_gender  
JOIN item_sales_summary i ON i.total_quantity_sold > 10  
ORDER BY c.ca_state, d.cd_gender, d.cd_marital_status;

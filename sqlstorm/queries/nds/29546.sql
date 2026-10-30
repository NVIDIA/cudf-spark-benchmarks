WITH Address_Stats AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_address_count, 
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Customer_Stats AS (
    SELECT 
        cd_gender, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
Combined_Stats AS (
    SELECT 
        a.ca_state,
        a.unique_address_count,
        a.max_street_name_length,
        a.min_street_name_length,
        a.avg_street_name_length,
        c.cd_gender,
        c.avg_purchase_estimate,
        c.customer_count
    FROM 
        Address_Stats a
    JOIN 
        Customer_Stats c ON a.ca_state = c.cd_gender 
)
SELECT 
    ca_state,
    SUM(unique_address_count) AS total_unique_addresses,
    AVG(max_street_name_length) AS average_max_street_length,
    AVG(min_street_name_length) AS average_min_street_length,
    AVG(avg_street_name_length) AS average_avg_street_length,
    SUM(customer_count) AS total_customers,
    COUNT(cd_gender) AS gender_groups
FROM 
    Combined_Stats
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT cd_gender) > 1
ORDER BY 
    total_unique_addresses DESC;
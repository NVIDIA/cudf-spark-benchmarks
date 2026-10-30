
WITH process_customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        CONCAT(TRIM(a.ca_street_number), ' ', TRIM(a.ca_street_name), ' ', TRIM(a.ca_street_type), ', ', TRIM(a.ca_city), ', ', TRIM(a.ca_state), ' ', TRIM(a.ca_zip)) AS full_address,
        d.d_date AS first_purchase_date,
        CD.cd_gender,
        CD.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_purchases,
        SUM(ss.ss_net_paid) AS total_store_spent
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        a.ca_street_number,
        a.ca_street_name,
        a.ca_street_type,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.d_date,
        CD.cd_gender,
        CD.cd_marital_status
)

SELECT 
    full_name,
    full_address,
    first_purchase_date,
    cd_gender,
    cd_marital_status,
    total_store_purchases,
    total_store_spent,
    CASE 
        WHEN total_store_spent > 1000 THEN 'High Value'
        WHEN total_store_spent BETWEEN 500 AND 1000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    process_customer_data
ORDER BY 
    total_store_spent DESC
LIMIT 100;

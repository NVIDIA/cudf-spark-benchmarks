
WITH CustomerAddressData AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state, 
        db.date_segment, 
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        (SELECT DISTINCT 
            CASE 
                WHEN d.d_year >= 2020 THEN '2020s'
                WHEN d.d_year >= 2010 THEN '2010s'
                WHEN d.d_year >= 2000 THEN '2000s'
                ELSE 'Before 2000s' 
            END AS date_segment,
            d.d_date_sk 
        FROM 
            date_dim d) db ON db.d_date_sk = c.c_first_sales_date_sk
    GROUP BY 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state, 
        db.date_segment
),
StringProcessingBenchmark AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state, 
        LPAD(NULLIF(REPLACE(ca.ca_city, ' ', ''), ''), 15, ' ') AS padded_city,
        UPPER(ca.ca_state) AS upper_state,
        LOWER(ca.ca_city) AS lower_city,
        customer_count
    FROM 
        CustomerAddressData ca
)
SELECT 
    padded_city, 
    upper_state, 
    lower_city, 
    AVG(customer_count) AS average_customers
FROM 
    StringProcessingBenchmark
GROUP BY 
    padded_city, 
    upper_state, 
    lower_city
ORDER BY 
    average_customers DESC;


WITH processed_data AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_date AS order_date,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS full_address,
        LENGTH(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS address_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
summary_data AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_orders,
        AVG(address_length) AS avg_address_length,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM 
        processed_data
    GROUP BY 
        ca_state
)
SELECT 
    sd.ca_state,
    sd.total_orders,
    sd.avg_address_length,
    sd.first_order_date,
    sd.last_order_date,
    ROW_NUMBER() OVER (ORDER BY sd.total_orders DESC) AS state_rank
FROM 
    summary_data sd
WHERE 
    sd.total_orders > 10
ORDER BY 
    sd.total_orders DESC;

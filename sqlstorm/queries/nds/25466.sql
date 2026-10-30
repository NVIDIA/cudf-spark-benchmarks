WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, coalesce(ca_suite_number, '')) AS full_address,
        LOWER(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip)) AS formatted_location
    FROM 
        customer_address
),
processed_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        customer c 
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
sales_data AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS sales_count
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk BETWEEN 5000 AND 5005 
    GROUP BY 
        s.ss_item_sk
)
SELECT 
    pa.ca_address_sk,
    pc.full_customer_name,
    pc.cd_gender,
    pc.cd_marital_status,
    pc.cd_purchase_estimate,
    sd.total_sales,
    sd.sales_count,
    pa.formatted_location
FROM 
    processed_addresses pa
JOIN 
    processed_customers pc ON pa.ca_address_sk = pc.c_customer_sk 
LEFT JOIN 
    sales_data sd ON pc.c_customer_sk = sd.ss_item_sk 
WHERE 
    pc.cd_marital_status = 'M' AND
    pc.cd_purchase_estimate > 1000
ORDER BY 
    sd.total_sales DESC, 
    pa.full_address ASC;
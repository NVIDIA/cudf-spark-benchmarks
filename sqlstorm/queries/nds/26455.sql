
WITH StringAggregation AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_name IS NOT NULL AND 
        c.c_last_name IS NOT NULL AND 
        ca.ca_city IS NOT NULL 
    GROUP BY 
        c.c_customer_id, full_name, full_address, cd.cd_marital_status, cd.cd_gender
),
StringAnalysis AS (
    SELECT 
        COUNT(*) AS total_customers,
        SUM(LENGTH(full_name)) AS total_name_length,
        SUM(LENGTH(full_address)) AS total_address_length,
        AVG(LENGTH(full_name)) AS avg_name_length,
        AVG(LENGTH(full_address)) AS avg_address_length,
        MAX(LENGTH(full_name)) AS max_name_length,
        MAX(LENGTH(full_address)) AS max_address_length,
        MIN(LENGTH(full_name)) AS min_name_length,
        MIN(LENGTH(full_address)) AS min_address_length
    FROM 
        StringAggregation
)

SELECT 
    total_customers,
    total_name_length,
    total_address_length,
    avg_name_length,
    avg_address_length,
    max_name_length,
    max_address_length,
    min_name_length,
    min_address_length
FROM 
    StringAnalysis;

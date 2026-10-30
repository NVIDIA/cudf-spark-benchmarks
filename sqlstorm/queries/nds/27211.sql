
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS formatted_address,
        LEFT(ca_city, 5) AS city_prefix,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
formatted_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    a.formatted_address,
    c.full_name,
    c.cd_gender,
    c.marital_status,
    c.purchase_estimate,
    COUNT(i.i_item_sk) AS total_items_purchased,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    processed_addresses a
JOIN 
    web_sales ws ON ws.ws_bill_addr_sk = a.ca_address_sk
JOIN 
    formatted_customers c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    a.city_prefix = 'NEW' 
    AND a.ca_state = 'NY' 
    AND c.purchase_estimate > 1000
GROUP BY 
    a.formatted_address, c.full_name, c.cd_gender, c.marital_status, c.purchase_estimate
ORDER BY 
    total_spent DESC
LIMIT 100;

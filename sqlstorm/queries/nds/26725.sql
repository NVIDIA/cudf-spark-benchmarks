
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        TRIM(BOTH ' ' FROM CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, ''))) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        CASE WHEN cd_gender = 'M' THEN 'Male' WHEN cd_gender = 'F' THEN 'Female' ELSE 'Other' END AS gender,
        cd_marital_status AS marital_status,
        ca_address_sk,
        full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_parts a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    ci.full_name,
    ci.gender,
    ci.marital_status,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_sales_price) AS average_order_value,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promo_names,
    STRING_AGG(DISTINCT CONCAT(CAST(ws.ws_sold_date_sk AS STRING), '->', CAST(ws.ws_net_paid AS STRING)), ', ') AS order_details
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ci.ca_state IN ('CA', 'NY', 'TX') 
GROUP BY 
    ci.full_name, ci.gender, ci.marital_status, ci.full_address, ci.ca_city, ci.ca_state, ci.ca_zip
ORDER BY 
    order_count DESC, average_order_value DESC
LIMIT 100;

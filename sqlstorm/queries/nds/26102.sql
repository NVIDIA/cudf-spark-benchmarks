
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(ca.ca_suite_number, '')) AS full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        ca.ca_zip,
        ca.ca_country,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.full_address,
    ci.city_state,
    ci.ca_zip,
    ci.ca_country,
    ci.cd_purchase_estimate,
    si.total_quantity_sold,
    si.total_sales_amount
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_item_sk
WHERE 
    ci.cd_dep_count > 0 AND 
    (ci.cd_gender = 'F' OR (ci.cd_marital_status = 'M' AND ci.cd_purchase_estimate > 1000))
ORDER BY 
    total_sales_amount DESC,
    full_name ASC
LIMIT 100;


WITH AddressComponents AS (
    SELECT 
        CONCAT(
            ca_street_number, ' ', 
            ca_street_name, ' ', 
            ca_street_type, ', ', 
            ca_city, ', ', 
            ca_state, ' ', 
            ca_zip
        ) AS full_address, 
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
        c_email_address, 
        cd_gender, 
        cd_marital_status, 
        c_current_cdemo_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_quantity, 
        ws_sales_price, 
        ws_order_number, 
        ws_item_sk, 
        ws_bill_customer_sk
    FROM 
        web_sales
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ac.full_address,
    si.ws_quantity,
    si.ws_sales_price,
    (si.ws_quantity * si.ws_sales_price) AS total_sales_value
FROM 
    CustomerInfo ci
JOIN 
    customer c ON ci.c_email_address = c.c_email_address
JOIN 
    AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
JOIN 
    SalesInfo si ON c.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    UPPER(ac.ca_country) = 'USA'
    AND ci.cd_marital_status = 'M'
GROUP BY 
    ci.full_name,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ac.full_address,
    si.ws_quantity,
    si.ws_sales_price
ORDER BY 
    total_sales_value DESC
LIMIT 100;

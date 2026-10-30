
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        UPPER(TRIM(ca_street_name)) AS formatted_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND
        ca_state IN ('CA', 'NY')
),
CustomerInfo AS (
    SELECT 
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        c_email_address,
        c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate > 50000
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.c_email_address,
    ai.ca_city,
    ai.ca_state,
    ai.full_address,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS order_count
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ci.c_email_address LIKE CONCAT('%', LOWER(REPLACE(ai.formatted_street_name, ' ', '_')), '%')
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;

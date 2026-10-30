
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        SUBSTRING(ca_street_name, 1, 10) AS short_street_name,
        CHAR_LENGTH(ca_street_name) AS street_name_length,
        ca_street_type,
        ca_address_sk
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        cd_education_status,
        TRIM(cd_credit_rating) AS credit_rating,
        cd_demo_sk
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.cd_gender,
    ci.marital_status,
    ci.cd_education_status,
    ai.ca_city,
    ai.ca_state,
    ai.short_street_name,
    ai.street_name_length,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_orders, 0) AS total_orders
FROM 
    CustomerInfo ci
JOIN 
    customer c ON c.c_current_cdemo_sk = ci.cd_demo_sk
JOIN 
    AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
LEFT JOIN 
    SalesInfo si ON c.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ai.street_name_length > 5
ORDER BY 
    total_sales DESC, 
    ai.ca_city ASC;

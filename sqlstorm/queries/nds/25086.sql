
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_customer_sk = cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_sales) AS total_sales
    FROM (
        SELECT 
            ws_bill_customer_sk,
            SUM(ws_sales_price * ws_quantity) AS ws_net_sales
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
        UNION ALL
        SELECT 
            ss_customer_sk,
            SUM(ss_sales_price * ss_quantity) AS ss_net_sales
        FROM 
            store_sales
        GROUP BY 
            ss_customer_sk
    ) AS Sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ai.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    si.total_sales
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    si.total_sales > 1000
ORDER BY 
    si.total_sales DESC
LIMIT 100;

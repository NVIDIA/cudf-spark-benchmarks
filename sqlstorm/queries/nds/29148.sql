
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        LEFT(ca.ca_zip, 5) AS zip_code_prefix,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales_value,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        ci.zip_code_prefix,
        COALESCE(si.total_sales_value, 0) AS total_sales_value,
        COALESCE(si.order_count, 0) AS order_count,
        CASE 
            WHEN COALESCE(si.total_sales_value, 0) > 1000 THEN 'High Value' 
            ELSE 'Regular Customer' 
        END AS customer_segment
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    ca_city,
    ca_state,
    zip_code_prefix,
    total_sales_value,
    order_count,
    customer_segment
FROM 
    CombinedInfo
WHERE 
    cd_marital_status = 'M'
    AND LOWER(ca_state) IN ('ny', 'ca', 'tx')
ORDER BY 
    total_sales_value DESC
LIMIT 100;

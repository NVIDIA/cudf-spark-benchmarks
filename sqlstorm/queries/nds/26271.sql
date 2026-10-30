
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating 
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FullReport AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.ca_country,
        ss.total_sales,
        ss.order_count
    FROM 
        CustomerInfo ci
    JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN 
        SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 1000 THEN 'Low Value Customer'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value Customer'
        ELSE 'High Value Customer' 
    END AS customer_value_category
FROM 
    FullReport
WHERE 
    ca_state = 'CA' AND cd_gender = 'F'
ORDER BY 
    total_sales DESC;

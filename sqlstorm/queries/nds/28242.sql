
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(NULLIF(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type), ' '), 'N/A') AS full_address,
        CASE 
            WHEN c.c_birth_month IS NOT NULL AND c.c_birth_day IS NOT NULL 
            THEN CONCAT(c.c_birth_month, '/', c.c_birth_day, '/', c.c_birth_year)
            ELSE 'Birthdate Not Available' 
        END AS birthdate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.full_address,
        ci.birthdate,
        sd.total_sales,
        sd.total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 100 THEN 'Low Value Customer'
        WHEN total_sales BETWEEN 100 AND 1000 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_category
FROM 
    CombinedData
ORDER BY 
    total_sales DESC NULLS LAST;

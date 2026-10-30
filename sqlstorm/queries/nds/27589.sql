
WITH EnhancedCustomer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender AS gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        CONCAT(c.c_birth_day, '-', c.c_birth_month, '-', c.c_birth_year) AS birth_date,
        ca.ca_city AS city,
        ca.ca_state AS state,
        REPLACE(c.c_email_address, '@', ' [at] ') AS sanitized_email
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
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ec.full_name,
    ec.gender,
    ec.marital_status,
    ec.birth_date,
    ec.city,
    ec.state,
    ec.sanitized_email,
    sd.total_sales,
    sd.order_count
FROM 
    EnhancedCustomer ec
LEFT JOIN 
    SalesData sd ON ec.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ec.city IS NOT NULL AND ec.state IS NOT NULL
ORDER BY 
    sd.total_sales DESC
LIMIT 100;

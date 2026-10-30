
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregatedData AS (
    SELECT 
        cd.customer_id,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.c_email_address,
        cd.full_address,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.customer_id = sd.customer_id
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    c_email_address,
    full_address,
    total_sales,
    CASE 
        WHEN total_sales >= 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 999 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    AggregatedData
ORDER BY 
    total_sales DESC
LIMIT 100;

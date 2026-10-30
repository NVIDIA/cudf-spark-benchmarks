
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(ca.ca_zip, 1, 5) AS zip_prefix,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ss.ss_ticket_number) AS total_store_sales,
        SUM(ss.ss_sales_price) AS total_sales_value,
        AVG(ss.ss_sales_price) AS avg_sale_value
    FROM 
        store_sales ss
    JOIN 
        CustomerInfo c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.full_name,
    SUM(sd.total_store_sales) AS total_store_sales,
    SUM(sd.total_sales_value) AS total_sales_value,
    ROUND(AVG(sd.avg_sale_value), 2) AS avg_sale_value,
    ci.ca_city,
    ci.ca_state,
    COUNT(DISTINCT ci.c_email_address) AS unique_emails
FROM 
    CustomerInfo ci
JOIN 
    SalesData sd ON ci.c_customer_sk = sd.c_customer_sk
GROUP BY 
    ci.full_name, ci.ca_city, ci.ca_state
HAVING 
    SUM(sd.total_sales_value) > 10000
ORDER BY 
    total_sales_value DESC
LIMIT 50;

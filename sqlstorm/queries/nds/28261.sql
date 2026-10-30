
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS uppercase_city,
        ca_state,
        REPLACE(ca_zip, '-', '') AS cleaned_zip
    FROM 
        customer_address
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        p.uppercase_city,
        p.cleaned_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales
    FROM 
        customer c
    JOIN 
        processed_addresses p ON c.c_current_addr_sk = p.ca_address_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, p.uppercase_city, p.cleaned_zip, cd.cd_gender, cd.cd_marital_status
) 
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.uppercase_city,
    cs.cleaned_zip,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    CASE 
        WHEN cs.total_sales = 0 THEN 'No Sales'
        WHEN cs.total_sales BETWEEN 1 AND 5 THEN 'Low Sales'
        WHEN cs.total_sales BETWEEN 6 AND 15 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    customer_summary cs
WHERE 
    cs.cd_gender = 'F'
ORDER BY 
    cs.total_sales DESC;

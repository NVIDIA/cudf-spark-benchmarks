
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        ca.ca_city, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
final_report AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_transactions, 0) AS total_transactions
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.c_customer_sk
)
SELECT 
    full_name,
    ca_city,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    total_transactions,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    final_report
ORDER BY 
    total_sales DESC;

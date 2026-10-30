
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2459816 AND 2459819 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cad.ca_city,
        cad.ca_state
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address cad ON c.c_current_addr_sk = cad.ca_address_sk
),
SalesData AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_transactions,
        d.cd_gender AS gender,
        d.cd_marital_status AS marital_status,
        d.cd_education_status AS education_status,
        d.ca_city,
        d.ca_state
    FROM 
        CustomerSales cs
    JOIN 
        Demographics d ON cs.c_customer_sk = d.cd_demo_sk
)
SELECT 
    gender,
    marital_status,
    education_status,
    ca_city,
    ca_state,
    COUNT(*) AS num_customers,
    AVG(total_sales) AS avg_sales,
    SUM(total_transactions) AS total_transactions
FROM 
    SalesData
GROUP BY 
    gender, marital_status, education_status, ca_city, ca_state
ORDER BY 
    num_customers DESC
LIMIT 10;

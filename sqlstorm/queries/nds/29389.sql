
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        c.full_name,
        c.ca_city,
        c.ca_state,
        c.ca_country,
        e.d_date
    FROM 
        store_sales ss
    JOIN 
        CustomerDetails c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        date_dim e ON ss.ss_sold_date_sk = e.d_date_sk
    GROUP BY 
        c.full_name, c.ca_city, c.ca_state, c.ca_country, e.d_date
),
FinalResult AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        ca_country,
        total_sales,
        total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS rank
    FROM 
        SalesSummary
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    total_transactions,
    rank
FROM 
    FinalResult
WHERE 
    rank <= 5
ORDER BY 
    ca_city, total_sales DESC;

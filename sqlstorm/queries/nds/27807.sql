
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_street_name,
        ca.ca_street_number,
        ca.ca_suite_number
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
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.ca_zip,
        cd.ca_street_number,
        cd.ca_street_name,
        cd.ca_suite_number,
        COALESCE(sd.total_spent, 0) AS total_spent,
        COALESCE(sd.order_count, 0) AS order_count,
        ROW_NUMBER() OVER (ORDER BY COALESCE(sd.total_spent, 0) DESC) AS rank
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    CONCAT(CAST(rank AS STRING), ' - ', full_name) AS customer_rank,
    total_spent,
    order_count,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    ca_street_number,
    ca_street_name,
    ca_suite_number
FROM 
    CustomerBenchmark
WHERE 
    rank <= 100
ORDER BY 
    rank;


WITH CustomerFullName AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address
    FROM 
        customer c
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
DemographicData AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        cf.full_name,
        s.total_spent,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_dep_count,
        COALESCE(s.order_count, 0) AS order_count
    FROM 
        CustomerFullName cf
    LEFT JOIN 
        SalesData s ON cf.c_customer_sk = s.customer_sk
    LEFT JOIN 
        customer c ON c.c_customer_sk = cf.c_customer_sk
    LEFT JOIN 
        DemographicData d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    full_name,
    total_spent,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_dep_count,
    order_count,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM 
    CustomerMetrics
WHERE 
    total_spent > 1000
ORDER BY 
    spending_rank;

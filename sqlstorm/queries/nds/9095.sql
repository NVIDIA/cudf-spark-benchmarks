
WITH CustomerOrderStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        MIN(ws.ws_sold_date_sk) AS first_order_date,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
),
AggregatedData AS (
    SELECT 
        cos.c_customer_sk,
        cos.c_first_name,
        cos.c_last_name,
        cos.total_spent,
        cos.total_orders,
        cos.first_order_date,
        cos.last_order_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN total_spent > 1000 THEN 'High Value'
            WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        CustomerOrderStats cos
    JOIN 
        CustomerDemographics cd ON cos.c_customer_sk = cd.cd_demo_sk
),
FinalOutput AS (
    SELECT 
        ad.c_customer_sk,
        ad.c_first_name,
        ad.c_last_name,
        ad.total_spent,
        ad.total_orders,
        ad.first_order_date,
        ad.last_order_date,
        ad.cd_gender,
        ad.cd_marital_status,
        ad.cd_education_status,
        ad.customer_value_segment
    FROM 
        AggregatedData ad
    ORDER BY 
        total_spent DESC, total_orders DESC
)
SELECT 
    *
FROM 
    FinalOutput
LIMIT 100;


WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        customer c
    JOIN 
        CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesWithDetails AS (
    SELECT 
        ss.ws_bill_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.c_birth_country,
        ss.total_quantity,
        ss.total_sales,
        ss.total_orders,
        ss.avg_net_paid
    FROM 
        SalesSummary ss
    JOIN 
        CustomerDetails cd ON ss.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT 
    c_birth_country,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_revenue,
    AVG(avg_net_paid) AS avg_order_value
FROM 
    SalesWithDetails
GROUP BY 
    c_birth_country
ORDER BY 
    total_revenue DESC
LIMIT 10;

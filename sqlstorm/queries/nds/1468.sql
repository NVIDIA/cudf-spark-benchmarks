
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_marital_status = 'M' AND cd.cd_dep_count > 2
),
CombinedData AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hvc.total_sales
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
),
FinalOutput AS (
    SELECT 
        *,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender_description,
        CASE 
            WHEN total_sales > 10000 THEN 'High Roller'
            WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Player'
            ELSE 'Casual Player'
        END AS customer_type
    FROM 
        CombinedData
)
SELECT 
    f.customer_type,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_sales_value,
    AVG(total_sales) AS average_sales
FROM 
    FinalOutput f
GROUP BY 
    f.customer_type
ORDER BY 
    total_sales_value DESC;


WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ss.ss_sold_date_sk BETWEEN 2459580 AND 2459585
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM 
        customer_demographics cd
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.purchase_category,
        cs.total_quantity,
        cs.total_sales,
        cs.total_transactions
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    SUM(ss.total_sales) AS total_sales_amount,
    AVG(ss.total_sales) AS average_sales_amount,
    COUNT(DISTINCT ss.c_customer_sk) AS number_of_customers,
    MAX(ss.total_sales) AS max_sales_single_transaction
FROM 
    SalesSummary ss
JOIN 
    CustomerDemographics cd ON ss.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender
ORDER BY 
    total_sales_amount DESC;

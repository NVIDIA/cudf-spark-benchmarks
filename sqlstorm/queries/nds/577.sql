
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_transactions,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(CASE WHEN cd.cd_purchase_estimate > 500 THEN 1 ELSE 0 END) AS high_value_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    hvc.total_sales, 
    hvc.total_transactions, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.high_value_count
FROM 
    HighValueCustomers hvc
JOIN 
    customer c ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    hvc.sales_rank <= 10
    AND cd.cd_gender IS NOT NULL
ORDER BY 
    hvc.total_sales DESC;

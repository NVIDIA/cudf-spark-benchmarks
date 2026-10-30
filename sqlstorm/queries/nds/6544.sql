
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_ext_sales_price) AS average_transaction_value
    FROM 
        customer c 
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2458849 AND 2458915
    GROUP BY 
        c.c_customer_sk
), 
DemographicAnalysis AS (
    SELECT 
        cd.cd_demo_sk,
        MAX(cd.cd_credit_rating) as max_credit_rating,
        MIN(cd.cd_purchase_estimate) as min_purchase_estimate,
        AVG(cd.cd_dep_count) as average_dependents
    FROM 
        customer_demographics cd 
    JOIN 
        CustomerSales cs ON cs.c_customer_sk = cd.cd_demo_sk 
    GROUP BY 
        cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        ds.max_credit_rating,
        ds.min_purchase_estimate,
        ds.average_dependents,
        cs.total_sales,
        cs.total_transactions,
        cs.average_transaction_value
    FROM 
        CustomerSales cs
    JOIN 
        DemographicAnalysis ds ON cs.c_customer_sk = ds.cd_demo_sk
)
SELECT 
    s.c_customer_sk,
    s.total_sales,
    s.total_transactions,
    s.average_transaction_value,
    CASE 
        WHEN s.total_sales > 1000 THEN 'High Value Customer'
        WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_category
FROM 
    SalesSummary s
ORDER BY 
    s.total_sales DESC
LIMIT 100;

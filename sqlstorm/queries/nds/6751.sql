
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS average_transaction_value,
        MIN(ss.ss_sales_price) AS min_transaction_value,
        MAX(ss.ss_sales_price) AS max_transaction_value
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesWithDemographics AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_transactions,
        cs.average_transaction_value,
        cs.min_transaction_value,
        cs.max_transaction_value,
        d.cd_gender,
        d.cd_marital_status,
        d.ib_lower_bound,
        d.ib_upper_bound,
        d.cd_purchase_estimate
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    SalesWithDemographics
ORDER BY 
    total_sales DESC
LIMIT 100;

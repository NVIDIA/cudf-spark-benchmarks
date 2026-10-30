
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
CTE_Income_Band AS (
    SELECT 
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_range
    FROM 
        income_band ib
)
SELECT 
    CTE_Customer_Sales.c_first_name,
    CTE_Customer_Sales.c_last_name,
    CTE_Customer_Sales.total_net_paid,
    CTE_Customer_Demographics.cd_gender,
    CTE_Customer_Demographics.cd_marital_status,
    CTE_Income_Band.income_range,
    RANK() OVER (PARTITION BY CTE_Customer_Demographics.cd_gender ORDER BY CTE_Customer_Sales.total_net_paid DESC) AS sales_rank
FROM 
    CTE_Customer_Sales
JOIN 
    CTE_Customer_Demographics ON CTE_Customer_Sales.c_customer_sk = CTE_Customer_Demographics.cd_demo_sk
LEFT JOIN 
    CTE_Income_Band ON CTE_Customer_Demographics.cd_demo_sk = CTE_Income_Band.ib_income_band_sk
WHERE 
    CTE_Customer_Sales.total_net_paid IS NOT NULL
ORDER BY 
    CTE_Customer_Sales.total_net_paid DESC
LIMIT 25;

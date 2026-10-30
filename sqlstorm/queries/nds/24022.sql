
WITH RankedSales AS (
    SELECT 
        cs_bill_customer_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_net_paid) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 10000 AND 10005
    GROUP BY 
        cs_bill_customer_sk, cs_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
        AND (cd_gender = 'F' OR cd_marital_status <> 'M')
),
MaxReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
    HAVING 
        COUNT(*) > 2
),
CustomerWithReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        MAX(mr.return_count) AS return_count,
        SUM(mr.total_return_amt) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        MaxReturns mr ON c.c_customer_sk = mr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    d.d_date,
    cs.total_quantity,
    cs.total_net_paid,
    cd.cd_gender,
    cd.cd_marital_status,
    cr.return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
        WHEN cd.cd_dep_count > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END AS dependent_status
FROM 
    date_dim d
JOIN 
    RankedSales cs ON d.d_date_sk = cs.cs_item_sk
JOIN 
    CustomerDemographics cd ON cs.cs_bill_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    CustomerWithReturns cr ON cs.cs_bill_customer_sk = cr.c_customer_sk
WHERE 
    d.d_year = 2023
    AND (cd.cd_credit_rating = 'Good' OR cd.cd_gender IS NULL)
ORDER BY 
    d.d_date, total_net_paid DESC
LIMIT 100
OFFSET 10;


WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(sr_return_amt, 0)) AS total_returned_amt,
        SUM(COALESCE(sr_return_tax, 0)) AS total_returned_tax
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
CustomerCombined AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returned_quantity,
        cr.total_returned_amt,
        cr.total_returned_tax,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_dependents,
        cd.avg_purchase_estimate
    FROM CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.total_returned_quantity,
    c.total_returned_amt,
    c.total_returned_tax,
    c.cd_gender,
    c.cd_marital_status,
    c.total_dependents,
    c.avg_purchase_estimate,
    CASE 
        WHEN c.total_returned_amt > 1000 THEN 'High Returner'
        WHEN c.total_returned_amt BETWEEN 500 AND 1000 THEN 'Medium Returner'
        ELSE 'Low Returner' 
    END AS return_category,
    RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_returned_amt DESC) AS gender_rank
FROM CustomerCombined c
WHERE c.total_returned_quantity > 0
ORDER BY c.total_returned_amt DESC
LIMIT 100;

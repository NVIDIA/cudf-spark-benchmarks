
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.purchase_rank <= 10
),
AggCustomerData AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        TopCustomers cd
    GROUP BY 
        cd.cd_gender
)
SELECT 
    acd.cd_gender,
    acd.customer_count,
    acd.average_purchase_estimate,
    CASE 
        WHEN acd.average_purchase_estimate > 1000 THEN 'High Value'
        WHEN acd.average_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    AggCustomerData acd
ORDER BY 
    acd.cd_gender;

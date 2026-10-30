
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate IS NOT NULL
),
MaxPurchase AS (
    SELECT 
        cd_gender,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        RankedCustomers
    GROUP BY 
        cd_gender
),
TopCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    JOIN 
        MaxPurchase mp ON rc.cd_gender = mp.cd_gender AND rc.cd_purchase_estimate = mp.max_purchase_estimate
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_purchase_estimate,
    CASE 
        WHEN tc.cd_purchase_estimate >= 1000 THEN 'High Value Customer'
        WHEN tc.cd_purchase_estimate >= 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_category
FROM 
    TopCustomers tc
ORDER BY 
    tc.cd_gender, tc.cd_purchase_estimate DESC;

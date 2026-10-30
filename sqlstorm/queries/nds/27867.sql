
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_purchase_estimate
    FROM 
        RankedCustomers c
    WHERE 
        c.rn <= 10
),
AggregatedData AS (
    SELECT 
        f.cd_gender,
        COUNT(*) AS customer_count,
        AVG(f.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(f.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        FilteredCustomers f
    GROUP BY 
        f.cd_gender
)
SELECT 
    CONCAT('Gender: ', ad.cd_gender) AS gender_info,
    CONCAT('Customer Count: ', ad.customer_count) AS customer_info,
    CONCAT('Average Purchase Estimate: $', ROUND(ad.avg_purchase_estimate, 2)) AS purchase_info,
    CONCAT('Max Purchase Estimate: $', ROUND(ad.max_purchase_estimate, 2)) AS max_purchase_info
FROM 
    AggregatedData ad
ORDER BY 
    ad.cd_gender;

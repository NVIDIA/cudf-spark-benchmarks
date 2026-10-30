
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY cr_return_amount DESC) as rn
    FROM 
        catalog_returns 
    WHERE 
        cr_return_quantity > 0
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
IncomeStats AS (
    SELECT 
        hd.hd_demo_sk,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    GROUP BY 
        hd.hd_demo_sk
),
ReturnStats AS (
    SELECT 
        DISTINCT r.cr_returning_customer_sk,
        SUM(r.cr_return_quantity) AS total_return_quantity,
        SUM(r.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns r
    WHERE 
        r.cr_return_amount IS NOT NULL
    GROUP BY 
        r.cr_returning_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    r.total_return_quantity,
    r.total_return_amount,
    CASE 
        WHEN r.total_return_amount IS NULL THEN 'No returns'
        ELSE 'Has returns'
    END AS return_status,
    CASE
        WHEN i.avg_vehicle_count > 2 THEN 'High Vehicle Ownership'
        WHEN i.avg_vehicle_count IS NULL THEN 'No vehicle data'
        ELSE 'Regular Vehicle Ownership'
    END AS vehicle_ownership_status
FROM 
    CustomerInfo ci
LEFT JOIN 
    ReturnStats r ON ci.c_customer_sk = r.cr_returning_customer_sk
LEFT JOIN 
    IncomeStats i ON ci.c_customer_sk = i.hd_demo_sk
WHERE 
    ci.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
    AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
ORDER BY 
    COALESCE(r.total_return_amount, 0) DESC,
    ci.c_last_name ASC
LIMIT 50;

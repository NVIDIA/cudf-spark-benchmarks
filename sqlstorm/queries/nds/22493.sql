
WITH RecentCustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (SELECT MAX(sr_returned_date_sk) FROM store_returns) - 30
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1980
),
IncomeData AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    HVC.c_first_name,
    HVC.c_last_name,
    HVC.cd_gender,
    HVC.cd_marital_status,
    COALESCE(RC.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(RC.total_return_amt, 0) AS total_return_amt,
    ID.ib_lower_bound,
    ID.ib_upper_bound,
    CASE 
        WHEN COALESCE(RC.total_return_amt, 0) > 1000 THEN 'High Returner'
        ELSE 'Standard Returner'
    END AS customer_type,
    CONCAT(HVC.c_first_name, ' ', HVC.c_last_name) AS full_name
FROM 
    HighValueCustomers HVC
LEFT JOIN 
    RecentCustomerReturns RC ON HVC.c_customer_sk = RC.sr_customer_sk
LEFT JOIN 
    IncomeData ID ON HVC.c_customer_sk = ID.hd_demo_sk
WHERE 
    (HVC.cd_gender = 'F' OR HVC.cd_marital_status = 'M')
AND 
    ID.ib_upper_bound - ID.ib_lower_bound > 15000
ORDER BY 
    total_return_amt DESC,
    full_name ASC
LIMIT 20 OFFSET 10;

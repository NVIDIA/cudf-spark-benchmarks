
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_month BETWEEN 1 AND 6
),
HeadOfHouseholds AS (
    SELECT 
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        COUNT(hd.hd_dep_count) AS dependent_count,
        SUM(hd.hd_vehicle_count) AS total_vehicles
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_demo_sk, hd.hd_income_band_sk
),
IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        income_band ib
)
SELECT 
    rc.full_name,
    rc.c_email_address,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    hdh.dependent_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    RankedCustomers rc
JOIN 
    HeadOfHouseholds hdh ON rc.c_customer_sk = hdh.hd_demo_sk
JOIN 
    IncomeBands ib ON hdh.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_gender, rc.cd_purchase_estimate DESC;

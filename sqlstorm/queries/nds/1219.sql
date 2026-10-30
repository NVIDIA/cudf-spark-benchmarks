
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS total_returned_orders
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rn
    FROM 
        customer_demographics
    LEFT JOIN 
        household_demographics ON hd_demo_sk = cd_demo_sk
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        CustomerReturns AS cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    JOIN 
        CustomerDemographics AS cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cr.total_returned_quantity > (SELECT AVG(total_returned_quantity) FROM CustomerReturns)
)
SELECT 
    hrc.c_customer_id,
    hrc.c_first_name,
    hrc.c_last_name,
    hrc.total_returned_quantity,
    hrc.total_returned_amount,
    CASE 
        WHEN hrc.cd_gender = 'F' THEN 'Female'
        WHEN hrc.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS Gender,
    hrc.cd_marital_status,
    hrc.cd_purchase_estimate,
    CASE 
        WHEN hrc.cd_purchase_estimate >= 1000 THEN 'High Value'
        WHEN hrc.cd_purchase_estimate BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Value_Category
FROM 
    HighReturnCustomers AS hrc
ORDER BY 
    hrc.total_returned_amount DESC
LIMIT 10;


WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_tax) AS total_tax
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
HighValueCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cr.unique_returns,
        cr.total_return_amt,
        cr.total_return_qty,
        cd.cd_purchase_estimate
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
    WHERE 
        cr.total_return_amt > (SELECT AVG(total_return_amt) FROM CustomerReturns)
)
SELECT 
    hvc.sr_customer_sk,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.unique_returns,
    hvc.total_return_amt,
    hvc.total_return_qty,
    hvc.cd_purchase_estimate,
    CASE 
        WHEN hvc.cd_gender = 'F' THEN 'Female'
        WHEN hvc.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS Gender_Description,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = hvc.sr_customer_sk AND ss.ss_sales_price > 100) AS high_value_sales_count,
    (SELECT 
        MAX(ws_ext_sales_price) 
     FROM 
        web_sales 
     WHERE 
        ws_bill_customer_sk = hvc.sr_customer_sk) AS max_web_sales_price
FROM 
    HighValueCustomers hvc
ORDER BY 
    hvc.total_return_amt DESC
LIMIT 10;

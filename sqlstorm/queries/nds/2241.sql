WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
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
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cr.total_return_amt,
        cr.total_returns,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_return_amt DESC) AS rn
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_purchase_estimate,
    COALESCE(tc.total_return_amt, 0) AS total_return_amt,
    COALESCE(tc.total_returns, 0) AS total_returns,
    CASE 
        WHEN tc.total_return_amt IS NULL THEN 'No Returns'
        WHEN tc.total_return_amt > 500 THEN 'High Value Returner'
        ELSE 'Regular Returner'
    END AS return_category
FROM 
    TopCustomers tc
WHERE 
    tc.rn <= 5 
ORDER BY 
    tc.cd_gender, 
    total_return_amt DESC;
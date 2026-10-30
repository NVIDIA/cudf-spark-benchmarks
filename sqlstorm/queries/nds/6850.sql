
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
),
CustomerWithDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        cd.*
    FROM customer c
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cr.total_returns_amt,
        cr.total_return_count
    FROM CustomerWithDemographics cd
    JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_return_count > 5
    ORDER BY cr.total_returns_amt DESC
    LIMIT 100
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returns_amt,
    tc.total_return_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating
FROM TopCustomers tc
JOIN CustomerDemographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_purchase_estimate > 500
ORDER BY tc.total_returns_amt DESC, tc.c_last_name ASC
LIMIT 50;


WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT sr.sr_item_sk) AS total_returned_items,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_return_tickets
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating
    HAVING 
        COUNT(DISTINCT sr.sr_ticket_number) > 0
),
TopReturningCustomers AS (
    SELECT 
        ci.*, 
        rr.total_return_amt,
        rr.total_returns
    FROM 
        CustomerInfo ci
    JOIN 
        RankedReturns rr ON ci.c_customer_sk = rr.sr_customer_sk
    WHERE 
        rr.return_rank <= 5
)
SELECT 
    trc.c_first_name,
    trc.c_last_name,
    trc.cd_gender,
    trc.cd_marital_status,
    trc.cd_education_status,
    trc.cd_purchase_estimate,
    trc.cd_credit_rating,
    trc.total_returned_items,
    trc.total_return_tickets,
    trc.total_return_amt
FROM 
    TopReturningCustomers trc
ORDER BY 
    trc.total_return_amt DESC;

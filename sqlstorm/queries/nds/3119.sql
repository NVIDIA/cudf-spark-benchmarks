
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        AVG(sr_return_quantity) AS avg_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cr.total_return_amt,
        cr.return_count,
        cd.purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_return_amt DESC) AS return_rank
    FROM 
        CustomerReturns AS cr
    JOIN 
        CustomerDemographics AS cd ON cr.sr_customer_sk = cd.c_customer_sk
    WHERE 
        cr.total_return_amt > 100
),
TopRankedReturns AS (
    SELECT 
        DISTINCT hrc.sr_customer_sk,
        hrc.cd_gender,
        hrc.cd_marital_status,
        hrc.cd_education_status,
        hrc.total_return_amt,
        hrc.return_count
    FROM 
        HighReturnCustomers AS hrc
    WHERE 
        hrc.return_rank <= 10
)
SELECT 
    s.s_store_id,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_transactions,
    AVG(ss.ss_net_paid) AS avg_net_paid
FROM 
    store AS s
LEFT JOIN 
    store_sales AS ss ON s.s_store_sk = ss.ss_store_sk
JOIN 
    TopRankedReturns AS tr ON ss.ss_customer_sk = tr.sr_customer_sk
GROUP BY 
    s.s_store_id
ORDER BY 
    total_net_profit DESC
LIMIT 5;

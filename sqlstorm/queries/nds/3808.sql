
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        COUNT(wr_order_number) AS web_return_count,
        SUM(wr_return_amt_inc_tax) AS web_total_return_amt,
        SUM(wr_return_quantity) AS web_total_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(cu.sr_customer_sk, wr.customer_sk) AS customer_sk,
        COALESCE(cu.return_count, 0) AS store_return_count,
        COALESCE(wr.web_return_count, 0) AS web_return_count,
        COALESCE(cu.total_return_amt, 0) AS store_total_return_amt,
        COALESCE(wr.web_total_return_amt, 0) AS web_total_return_amt
    FROM 
        CustomerReturns cu
    FULL OUTER JOIN 
        WebReturns wr ON cu.sr_customer_sk = wr.customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cr.store_return_count,
    cr.web_return_count,
    cr.store_total_return_amt,
    cr.web_total_return_amt,
    (cr.store_total_return_amt + cr.web_total_return_amt) AS total_return_amount,
    DENSE_RANK() OVER (ORDER BY (cr.store_total_return_amt + cr.web_total_return_amt) DESC) AS return_rank
FROM 
    CombinedReturns cr
JOIN 
    CustomerDemographics cd ON cr.customer_sk = cd.c_customer_sk
WHERE 
    cr.store_total_return_amt IS NOT NULL OR cr.web_total_return_amt IS NOT NULL
ORDER BY 
    total_return_amount DESC
LIMIT 100;

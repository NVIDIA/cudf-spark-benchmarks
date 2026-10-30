
WITH CustomerRefunds AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_refund_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebRefunds AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_refund_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    COALESCE(cr.total_store_returns, 0) AS store_return_count,
    COALESCE(cr.total_refund_amount, 0) AS store_refund_amount,
    COALESCE(wr.total_web_returns, 0) AS web_return_count,
    COALESCE(wr.total_web_refund_amount, 0) AS web_refund_amount,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerRefunds cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    WebRefunds wr ON cd.c_customer_sk = wr.wr_returning_customer_sk
WHERE 
    (cr.total_store_returns > 2 OR wr.total_web_returns > 3)
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status IS NOT NULL
ORDER BY 
    store_refund_amount DESC 
LIMIT 50;

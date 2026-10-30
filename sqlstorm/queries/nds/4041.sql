
WITH CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returned_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT wr.wr_order_number) AS total_return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
TotalReturns AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_returned_quantity, 0) + COALESCE(wr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) + COALESCE(wr.total_returned_amount, 0) AS total_returned_amount,
        (COALESCE(cr.total_return_count, 0) + COALESCE(wr.total_return_count, 0)) AS total_return_count
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN
        WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(CASE WHEN tr.total_returned_quantity > 0 THEN tr.total_returned_quantity ELSE 0 END) AS total_returned_quantity,
        COUNT(CASE WHEN tr.total_return_count > 0 THEN tr.total_return_count ELSE NULL END) AS return_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        TotalReturns tr ON c.c_customer_sk = tr.customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.total_returned_quantity,
    cd.return_count,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment
FROM 
    CustomerDemographics cd
WHERE 
    cd.return_count > 0 
ORDER BY 
    cd.total_returned_quantity DESC
LIMIT 100;

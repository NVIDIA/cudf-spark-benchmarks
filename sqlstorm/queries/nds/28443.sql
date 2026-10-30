
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(sr_return_tax), 0) AS total_return_tax,
        COUNT(DISTINCT sr_ticket_number) AS unique_return_tickets
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
ReturnSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.total_returns) AS total_returns,
        SUM(cr.total_return_amount) AS total_return_amount,
        SUM(cr.total_return_tax) AS total_return_tax,
        COUNT(DISTINCT cr.c_customer_id) AS customer_return_count
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.c_customer_id IS NOT NULL
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_tax, 0) AS total_return_tax,
    cd.customer_count,
    (COALESCE(r.total_returns, 0) * 100.0 / NULLIF(cd.customer_count, 0)) AS return_rate_percentage
FROM 
    CustomerDemographics cd
LEFT JOIN 
    ReturnSummary r ON cd.cd_gender = r.cd_gender AND cd.cd_marital_status = r.cd_marital_status
ORDER BY 
    cd.cd_gender, cd.cd_marital_status;


WITH RankedReturns AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        RANK() OVER (PARTITION BY sr.sr_customer_sk ORDER BY COUNT(sr.sr_item_sk) DESC) AS return_rank
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
HighReturnCustomers AS (
    SELECT
        r.sr_customer_sk,
        r.total_returns,
        r.total_return_amount,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_web_returns,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_web_return_amount,
        r.return_rank
    FROM 
        RankedReturns r
    LEFT JOIN 
        web_returns wr ON r.sr_customer_sk = wr.wr_returning_customer_sk
    WHERE 
        r.total_returns > (SELECT AVG(total_returns) FROM RankedReturns)
    GROUP BY 
        r.sr_customer_sk, r.total_returns, r.total_return_amount, r.return_rank
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN c.c_birth_month IS NULL OR c.c_birth_day IS NULL THEN 'Unknown' 
            ELSE CONCAT(c.c_birth_month, '/', c.c_birth_day, '/', c.c_birth_year) 
        END AS birth_date,
        ROW_NUMBER() OVER (ORDER BY c.c_last_name) AS row_num
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalResults AS (
    SELECT 
        hrc.sr_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        hrc.total_returns,
        hrc.total_return_amount,
        hrc.total_web_returns,
        hrc.total_web_return_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.birth_date,
        CASE 
            WHEN hrc.return_rank = 1 THEN 'Top Returning Customer' 
            ELSE 'Regular Customer' 
        END AS customer_type
    FROM 
        HighReturnCustomers hrc
    JOIN 
        CustomerDetails cd ON hrc.sr_customer_sk = cd.c_customer_sk
)
SELECT
    f.sr_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_returns,
    f.total_return_amount,
    f.total_web_returns,
    f.total_web_return_amount,
    f.cd_gender,
    f.cd_marital_status,
    f.birth_date,
    f.customer_type
FROM 
    FinalResults f 
WHERE
    f.total_return_amount > (
        SELECT AVG(total_return_amount)
        FROM FinalResults
    )
ORDER BY 
    f.total_return_amount DESC;

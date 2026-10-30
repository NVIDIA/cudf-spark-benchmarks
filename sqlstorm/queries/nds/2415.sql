
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returns,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), ReturnDetails AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        cd.cd_gender,
        cd.marital_status,
        cd.ib_lower_bound,
        cd.ib_upper_bound
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cr.total_returns > 0
), RankedReturns AS (
    SELECT 
        rd.c_customer_sk,
        rd.total_returns,
        rd.total_return_amount,
        rd.cd_gender,
        rd.marital_status,
        rd.ib_lower_bound,
        rd.ib_upper_bound,
        RANK() OVER (PARTITION BY rd.marital_status ORDER BY rd.total_return_amount DESC) AS rank
    FROM 
        ReturnDetails rd
)
SELECT 
    r.cd_gender,
    r.marital_status,
    COUNT(r.c_customer_sk) AS num_customers,
    AVG(r.total_return_amount) AS avg_return_amount,
    SUM(r.total_returns) AS total_returns_all,
    SUM(CASE 
        WHEN r.ib_lower_bound IS NOT NULL AND r.ib_upper_bound IS NOT NULL THEN 1 
        ELSE 0 
    END) AS income_band_customers
FROM 
    RankedReturns r
WHERE 
    r.rank <= 10
GROUP BY 
    r.cd_gender, r.marital_status
ORDER BY 
    r.cd_gender, r.marital_status;


WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_ship_cost) AS total_return_ship_cost
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_return_tax) AS total_web_return_tax
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
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_units_sold
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
)
SELECT 
    cd.c_customer_sk,
    COALESCE(cr.total_returns, 0) AS total_store_returns,
    COALESCE(cr.total_return_amt, 0) AS total_store_return_amt,
    COALESCE(wr.total_web_returns, 0) AS total_web_returns,
    COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt,
    ss.total_net_profit,
    ss.total_units_sold,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown' 
    END AS gender_desc,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS marital_status_desc
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    WebReturns wr ON cd.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ss_customer_sk
WHERE 
    (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NOT NULL)
    AND (cd.hd_income_band_sk IS NOT NULL OR ss.total_net_profit > 0)
ORDER BY 
    total_net_profit DESC,
    total_store_return_amt DESC;


WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_tax) AS total_returned_tax,
        COUNT(*) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_web_returned_quantity,
        SUM(wr_return_amt) AS total_web_returned_amount,
        SUM(wr_return_tax) AS total_web_returned_tax,
        COUNT(*) AS total_web_returns
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
        cd.cd_education_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_web_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        CR.total_returned_quantity,
        CR.total_returned_amount,
        WR.total_web_returned_quantity,
        WR.total_web_returned_amount,
        COALESCE(CR.total_returns, 0) + COALESCE(WR.total_web_returns, 0) AS total_combined_returns
    FROM 
        CustomerReturns CR
    FULL OUTER JOIN 
        WebReturns WR ON CR.sr_customer_sk = WR.wr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(CR.total_combined_returns, 0) AS total_combined_returns,
        COALESCE(SD.total_web_sales, 0) AS total_web_sales
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CombinedReturns CR ON cd.c_customer_sk = CR.customer_sk
    LEFT JOIN 
        SalesData SD ON cd.c_customer_sk = SD.customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_education_status,
    fr.total_combined_returns,
    fr.total_web_sales,
    CASE 
        WHEN fr.total_combined_returns > 0 AND fr.total_web_sales > 1000 THEN 'High Engagement'
        WHEN fr.total_combined_returns = 0 AND fr.total_web_sales < 500 THEN 'Low Engagement'
        ELSE 'Moderate Engagement'
    END AS engagement_level,
    CONCAT(fr.cd_gender, ' ', fr.cd_marital_status, ' ', fr.cd_education_status) AS demographic_summary
FROM 
    FinalReport fr
WHERE 
    fr.cd_gender IS NOT NULL
ORDER BY 
    fr.total_combined_returns DESC, 
    fr.total_web_sales DESC
LIMIT 100;

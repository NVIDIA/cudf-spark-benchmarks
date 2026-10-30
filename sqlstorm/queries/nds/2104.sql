
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(DISTINCT sr_ticket_number) AS total_returns, 
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesByCustomer AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    COALESCE(cd.cd_gender, 'N/A') AS gender,
    COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
    COALESCE(cr.total_returns, 0) AS returns_count,
    COALESCE(cr.total_return_amount, 0) AS return_amount,
    COALESCE(sbc.total_net_profit, 0) AS net_profit,
    CASE 
        WHEN cr.total_returns IS NULL THEN 'No Returns'
        WHEN cr.total_returns = 0 THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    SalesByCustomer sbc ON cd.c_customer_sk = sbc.ws_bill_customer_sk
WHERE 
    (cd.cd_purchase_estimate > 1000 OR cd.cd_credit_rating = 'Excellent')
    AND (cd.cd_dep_count IS NOT NULL AND cd.cd_dep_count > 2)
ORDER BY 
    return_status DESC, net_profit DESC
LIMIT 100;

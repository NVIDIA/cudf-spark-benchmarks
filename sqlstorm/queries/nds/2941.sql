
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS rank
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
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
ReturnComparison AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(rr.total_return_amt, 0) AS returns,
        COALESCE(sa.total_net_profit, 0) AS net_profit,
        sa.order_count
    FROM 
        CustomerDemographics c
    LEFT JOIN 
        RankedReturns rr ON c.c_customer_sk = rr.wr_returning_customer_sk
    LEFT JOIN 
        SalesAnalysis sa ON c.c_customer_sk = sa.ws_bill_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.returns,
    r.net_profit,
    r.order_count,
    CASE 
        WHEN r.returns > r.net_profit THEN 'High Return' 
        WHEN r.returns < r.net_profit THEN 'Profit' 
        ELSE 'Equal' 
    END AS return_to_profit_ratio,
    (r.returns + r.net_profit) / NULLIF(r.order_count, 0) AS average_per_order
FROM 
    ReturnComparison r
WHERE 
    r.order_count > 0
ORDER BY 
    average_per_order DESC;

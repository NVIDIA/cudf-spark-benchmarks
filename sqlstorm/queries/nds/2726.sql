
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS num_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd 
    ON 
        c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStat AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.num_returns, 0) AS num_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN cr.total_return_amt > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr 
    ON 
        cd.c_customer_sk = cr.sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        rs.c_first_name,
        rs.c_last_name,
        rs.cd_gender,
        rs.cd_marital_status,
        rs.num_returns,
        rs.total_return_amt,
        COALESCE(ss.total_profit, 0) AS total_profit,
        COALESCE(ss.total_orders, 0) AS total_orders,
        CASE 
            WHEN ss.total_profit > 1000 THEN 'High Value'
            WHEN ss.total_profit > 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        ReturnStat rs
    LEFT JOIN 
        SalesSummary ss 
    ON 
        rs.c_customer_sk = ss.customer_sk
)
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY cd_marital_status ORDER BY total_profit DESC) AS rank_within_marital_status
FROM 
    FinalReport
WHERE 
    total_orders > 0
AND 
    num_returns > 0
ORDER BY 
    total_profit DESC, num_returns DESC;

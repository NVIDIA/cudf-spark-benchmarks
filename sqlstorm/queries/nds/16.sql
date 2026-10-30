
WITH CustomerReturns AS (
    SELECT 
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        sr_customer_sk AS customer_sk
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amount,
        wr_returning_customer_sk AS customer_sk
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregateReturns AS (
    SELECT 
        COALESCE(C.customer_sk, W.customer_sk) AS customer_sk,
        C.total_store_returns,
        C.total_return_amount,
        W.total_web_returns,
        W.total_web_return_amount
    FROM 
        CustomerReturns C
    FULL OUTER JOIN 
        WebReturns W ON C.customer_sk = W.customer_sk
),
FinalData AS (
    SELECT 
        A.customer_sk,
        COALESCE(S.total_sales, 0) AS total_sales,
        A.total_store_returns,
        A.total_return_amount,
        A.total_web_returns,
        A.total_web_return_amount,
        (COALESCE(S.total_sales, 0) - COALESCE(A.total_return_amount, 0) - COALESCE(A.total_web_return_amount, 0)) AS net_profit
    FROM 
        AggregateReturns A
    LEFT JOIN 
        SalesData S ON A.customer_sk = S.customer_sk
)

SELECT 
    F.customer_sk,
    F.total_sales,
    F.total_store_returns,
    F.total_web_returns,
    F.net_profit,
    CASE 
        WHEN F.net_profit < 0 THEN 'Loss'
        WHEN F.net_profit = 0 THEN 'Break-even'
        ELSE 'Profit'
    END AS profit_status
FROM 
    FinalData F
WHERE 
    (F.total_store_returns > 0 OR F.total_web_returns > 0)
ORDER BY 
    F.net_profit DESC;


WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales_amt,
        COUNT(ws_order_number) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedReturns AS (
    SELECT 
        cr.sr_customer_sk,
        COALESCE(cr.total_return_amt, 0) AS total_store_return_amt,
        COALESCE(wr.total_return_amt, 0) AS total_web_return_amt,
        cr.total_returns AS total_store_returns,
        wr.total_returns AS total_web_returns
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
FinalData AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_store_return_amt, 0) AS store_return_amt,
        COALESCE(cr.total_web_return_amt, 0) AS web_return_amt,
        sd.total_sales_amt
    FROM 
        customer c
    LEFT JOIN 
        CombinedReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.customer_sk
)
SELECT 
    f.c_customer_id,
    f.store_return_amt,
    f.web_return_amt,
    f.total_sales_amt,
    ROUND((f.store_return_amt + f.web_return_amt) / NULLIF(f.total_sales_amt, 0), 2) AS return_rate
FROM 
    FinalData f
WHERE 
    f.total_sales_amt > 0
ORDER BY 
    return_rate DESC
LIMIT 10;

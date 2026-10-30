
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_sales_count,
        AVG(ws_net_paid_inc_tax) AS avg_payment
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnSummary AS (
    SELECT 
        COALESCE(cr.cr_returning_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_return_amt, 0) AS total_returns,
        COALESCE(cr.return_count, 0) + COALESCE(wr.web_return_count, 0) AS total_returns_count
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.cr_returning_customer_sk = wr.wr_returning_customer_sk
)
SELECT 
    sd.customer_sk,
    sd.total_net_profit,
    sd.total_sales_count,
    sd.avg_payment,
    rs.total_returns,
    rs.total_returns_count,
    CASE 
        WHEN rs.total_returns_count > 0 THEN 
            ROUND((rs.total_returns / sd.total_net_profit) * 100, 2)
        ELSE 
            0 
    END AS return_percentage
FROM 
    SalesData sd
LEFT JOIN 
    ReturnSummary rs ON sd.customer_sk = rs.customer_sk
WHERE 
    sd.total_net_profit > 0 
    AND sd.total_sales_count >= 10
ORDER BY 
    return_percentage DESC
LIMIT 50;

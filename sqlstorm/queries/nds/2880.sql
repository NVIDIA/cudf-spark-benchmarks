
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_web_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_web_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregateSales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(ws.total_web_sales_quantity, 0) AS total_web_sales_quantity,
        (COALESCE(ws.total_web_sales_amount, 0) - COALESCE(cr.total_returned_amount, 0)) AS net_web_sales
    FROM 
        customer AS c
    LEFT JOIN 
        CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    r.r_reason_desc AS return_reason,
    ag.total_returned_quantity,
    ag.total_web_sales_quantity,
    ag.net_web_sales,
    ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY ag.net_web_sales DESC) AS rank
FROM 
    AggregateSales AS ag
LEFT JOIN 
    store_returns AS sr ON ag.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason AS r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    ag.net_web_sales > 0
ORDER BY 
    r.r_reason_desc, ag.net_web_sales DESC;

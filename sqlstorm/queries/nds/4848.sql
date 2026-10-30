
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 2451000 AND 2452000 
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_qty,
        SUM(ws_net_paid) AS total_sales_amt,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451000 AND 2452000 
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returned_qty, 0) AS total_returns,
        COALESCE(sd.total_sales_qty, 0) AS total_sales,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(sd.total_sales_amt, 0) AS total_sales_amt,
        COALESCE(sd.avg_net_profit, 0) AS avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
RankedData AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY total_returns ORDER BY total_sales_amt DESC) AS return_rank
    FROM 
        CombinedData
)
SELECT 
    c.c_customer_id,
    r.total_returns,
    r.total_sales,
    r.total_returned_amt,
    r.total_sales_amt,
    r.avg_net_profit,
    CASE 
        WHEN r.total_sales_amt > 0 THEN (r.total_returned_amt / r.total_sales_amt) * 100
        ELSE NULL 
    END AS return_percentage,
    CASE 
        WHEN r.total_returns > 5 THEN 'High Return Customer'
        WHEN r.total_returns BETWEEN 2 AND 5 THEN 'Moderate Return Customer'
        ELSE 'Low Return Customer'
    END AS customer_category
FROM 
    RankedData r
INNER JOIN 
    customer c ON r.c_customer_id = c.c_customer_id
WHERE 
    r.return_rank <= 10
ORDER BY 
    r.total_sales_amt DESC;

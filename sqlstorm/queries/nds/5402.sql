
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amount,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
DailyPerformance AS (
    SELECT 
        d.d_date AS sales_date,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit
    FROM 
        date_dim d
    LEFT JOIN 
        CustomerReturns cr ON d.d_date_sk = cr.sr_returned_date_sk
    LEFT JOIN 
        SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
)
SELECT 
    sales_date,
    total_returns,
    total_return_amount,
    total_sales,
    total_sales_amount,
    total_net_profit,
    ROUND((total_sales_amount - total_return_amount) / NULLIF(total_sales_amount, 0) * 100, 2) AS return_rate,
    ROUND((total_net_profit / NULLIF(total_sales_amount, 0)) * 100, 2) AS profit_margin
FROM 
    DailyPerformance
WHERE 
    sales_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
ORDER BY 
    sales_date;


WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
DailyPerformance AS (
    SELECT 
        dd.d_date AS sales_date,
        COALESCE(SD.total_sold, 0) AS total_sold,
        COALESCE(CR.return_count, 0) AS return_count,
        (COALESCE(SD.total_sold, 0) - COALESCE(CR.return_count, 0)) AS net_sales,
        COALESCE(SD.total_profit, 0) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY dd.d_date) AS row_num
    FROM 
        date_dim dd
    LEFT JOIN SalesData SD ON dd.d_date_sk = SD.ws_sold_date_sk
    LEFT JOIN CustomerReturns CR ON dd.d_date_sk = CR.sr_returned_date_sk
)
SELECT 
    sales_date,
    total_sold,
    return_count,
    net_sales,
    total_profit,
    CASE 
        WHEN total_sold = 0 THEN 'No sales'
        WHEN return_count > total_sold THEN 'Refund Madness'
        ELSE 'Normal Operation' 
    END AS performance_status
FROM 
    DailyPerformance
WHERE 
    sales_date BETWEEN '2023-10-01' AND '2023-10-31'
      AND (net_sales - total_profit) IS NOT NULL
ORDER BY 
    sales_date ASC
LIMIT 10;


WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(*) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
RankedReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returned,
        cr.return_count,
        ROW_NUMBER() OVER (ORDER BY cr.total_returned DESC) AS rank
    FROM 
        CustomerReturns cr
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS sales_count,
        ws.ws_ship_customer_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
            (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_ship_customer_sk
)
SELECT 
    d.d_date AS sales_date,
    COALESCE(RR.total_returned, 0) AS total_returns,
    COALESCE(SD.total_sales, 0) AS total_sales,
    (COALESCE(SD.total_sales, 0) - COALESCE(RR.total_returned, 0)) AS net_sales
FROM 
    date_dim d
LEFT JOIN 
    RankedReturns RR ON RR.sr_customer_sk = d.d_date_sk
LEFT JOIN 
    SalesData SD ON SD.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    sales_date ASC;

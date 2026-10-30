
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_return_time_sk, sr_item_sk, sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
SalesWithReturns AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerReturns cr ON sd.ws_item_sk = cr.sr_item_sk AND sd.ws_sold_date_sk = cr.sr_returned_date_sk
),
FinalResults AS (
    SELECT 
        s.ws_sold_date_sk,
        s.ws_item_sk,
        s.total_sales,
        s.total_sales_amount,
        s.total_returns,
        s.total_return_amount,
        (s.total_sales_amount - s.total_return_amount) AS net_sales,
        CASE WHEN s.total_returns > 0 OR s.total_returns IS NULL THEN TRUE ELSE FALSE END AS has_returns,
        ROW_NUMBER() OVER (PARTITION BY s.ws_sold_date_sk ORDER BY s.total_sales_amount DESC) AS sales_rank
    FROM 
        SalesWithReturns s
)
SELECT 
    d.d_date AS sales_date,
    i.i_item_id AS item_id,
    i.i_item_desc AS item_description,
    r.total_sales,
    r.total_sales_amount,
    r.total_returns,
    r.total_return_amount,
    r.net_sales,
    r.has_returns,
    r.sales_rank
FROM 
    FinalResults r
JOIN 
    date_dim d ON r.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year = 2023 AND r.sales_rank <= 10
ORDER BY 
    d.d_date, r.total_sales_amount DESC;

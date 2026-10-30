
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk, 
        i.i_item_desc, 
        rs.total_quantity
    FROM 
        RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, 
        sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        tsi.ws_item_sk,
        tsi.i_item_desc,
        tsi.total_quantity,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        (tsi.total_quantity - COALESCE(cr.return_count, 0)) AS net_sales
    FROM 
        TopSellingItems tsi
    LEFT JOIN CustomerReturns cr ON tsi.ws_item_sk = cr.sr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.i_item_desc,
    s.total_quantity,
    s.return_count,
    s.total_return_amt,
    s.net_sales,
    CASE 
        WHEN s.net_sales < 0 THEN 'Negative Sales'
        WHEN s.net_sales = 0 THEN 'No Sales'
        ELSE 'Positive Sales'
    END AS sales_status
FROM 
    SalesAndReturns s
ORDER BY 
    s.net_sales DESC;

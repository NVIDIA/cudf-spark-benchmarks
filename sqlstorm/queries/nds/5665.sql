
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales_amt
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemPerformance AS (
    SELECT 
        r.sr_item_sk AS cs_item_sk,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ss.total_sales_amt, 0) AS total_sales_amt
    FROM 
        (SELECT DISTINCT sr_item_sk FROM CustomerReturns) AS r
    FULL OUTER JOIN SalesSummary ss ON r.sr_item_sk = ss.ws_item_sk
    LEFT JOIN CustomerReturns cr ON r.sr_item_sk = cr.sr_item_sk
),
FinalReport AS (
    SELECT 
        ip.cs_item_sk,
        ip.return_count,
        ip.total_return_amt,
        ip.total_quantity_sold,
        ip.total_sales_amt,
        CASE 
            WHEN ip.total_quantity_sold > 0 THEN (ip.total_return_amt / ip.total_quantity_sold) * 100
            ELSE 0
        END AS return_rate
    FROM 
        ItemPerformance ip
)
SELECT 
    a.i_item_id,
    a.i_item_desc,
    f.return_count,
    f.total_return_amt,
    f.total_quantity_sold,
    f.total_sales_amt,
    f.return_rate
FROM 
    FinalReport f
JOIN 
    item a ON f.cs_item_sk = a.i_item_sk
WHERE 
    f.return_rate > 10
ORDER BY 
    f.return_rate DESC
LIMIT 100;

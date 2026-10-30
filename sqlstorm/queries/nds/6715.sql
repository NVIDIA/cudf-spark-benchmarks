
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
SalesData AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sales_quantity,
        SUM(ss_net_paid) AS total_sales_amt
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
),
CombinedData AS (
    SELECT 
        s.ss_sold_date_sk AS date_sk,
        s.ss_item_sk AS item_sk,
        COALESCE(r.return_count, 0) AS return_count,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        s.total_sales_quantity,
        s.total_sales_amt
    FROM 
        SalesData s
    LEFT JOIN 
        CustomerReturns r ON s.ss_sold_date_sk = r.sr_returned_date_sk AND s.ss_item_sk = r.sr_item_sk
),
Analysis AS (
    SELECT 
        item_sk,
        SUM(total_sales_quantity) AS total_sales_quantity,
        SUM(total_sales_amt) AS total_sales_amt,
        SUM(return_count) AS total_returns,
        SUM(total_return_amt) AS total_return_amt,
        CASE 
            WHEN SUM(total_sales_amt) > 0 THEN 
                (SUM(total_return_amt) / SUM(total_sales_amt)) * 100 
            ELSE 0 
        END AS return_percentage
    FROM 
        CombinedData
    GROUP BY 
        item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    a.total_sales_quantity,
    a.total_sales_amt,
    a.total_returns,
    a.total_return_amt,
    a.return_percentage
FROM 
    Analysis a
JOIN 
    item i ON a.item_sk = i.i_item_sk
ORDER BY 
    a.return_percentage DESC, a.total_sales_amt DESC
LIMIT 10;

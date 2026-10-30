
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 31
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        sr_item_sk
),
SalesComparison AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        COALESCE(rr.return_count, 0) AS return_count,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN rs.total_sales IS NULL THEN 'No Sales'
            WHEN rr.total_return_amt > rs.total_sales THEN 'Loss' 
            ELSE 'Profit' 
        END AS sales_status
    FROM 
        RankedSales rs
    LEFT JOIN 
        RecentReturns rr ON rs.ws_item_sk = rr.sr_item_sk
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sc.total_quantity,
    sc.total_sales,
    sc.return_count,
    sc.total_return_amt,
    sc.sales_status,
    CASE 
        WHEN sc.sales_status = 'Loss' THEN 'Review Required'
        ELSE 'Normal'
    END AS action_required
FROM 
    SalesComparison sc
JOIN 
    item i ON sc.ws_item_sk = i.i_item_sk
WHERE 
    (sc.sales_status = 'Profit' OR sc.sales_status = 'Loss') 
    AND (sc.total_sales - sc.total_return_amt) > 100
ORDER BY 
    sc.total_sales DESC, 
    i.i_item_desc ASC;


WITH  SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 0 
            ELSE ws.ws_sales_price * ws.ws_quantity 
        END AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451918 AND 2451970
), HighestSales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.total_sales) AS total_sales,
        COUNT(DISTINCT sd.ws_item_sk) AS item_count
    FROM SalesData sd
    WHERE sd.rn <= 3
    GROUP BY sd.ws_order_number
), CustomerReturns AS (
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_order_number, wr.wr_item_sk
), SalesAndReturns AS (
    SELECT 
        hs.ws_order_number,
        hs.total_sales,
        hs.item_count,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        hs.total_sales - COALESCE(cr.total_return_amt, 0) AS net_sales
    FROM HighestSales hs
    LEFT JOIN CustomerReturns cr ON hs.ws_order_number = cr.wr_order_number
)
SELECT 
    s.ws_order_number,
    s.total_sales,
    s.item_count,
    s.total_return_quantity,
    s.total_return_amt,
    s.net_sales,
    CASE 
        WHEN s.net_sales > 1000 THEN 'High'
        WHEN s.net_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM SalesAndReturns s
WHERE s.net_sales IS NOT NULL
ORDER BY s.net_sales DESC;

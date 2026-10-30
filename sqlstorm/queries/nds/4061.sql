
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        total_sales 
    FROM RankedSales 
    WHERE sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns 
    GROUP BY wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(ts.total_sales, 0) AS total_sales,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ts.total_sales, 0) - COALESCE(cr.total_return_amt, 0) AS net_sales
    FROM (
        SELECT DISTINCT ws_item_sk FROM web_sales
    ) ws
    LEFT JOIN TopSales ts ON ws.ws_item_sk = ts.ws_item_sk
    LEFT JOIN CustomerReturns cr ON cr.wr_returning_customer_sk = ws.ws_item_sk
),
FinalResults AS (
    SELECT 
        a.ca_city,
        SUM(swr.total_sales) AS total_sales,
        SUM(swr.return_count) AS total_returns,
        AVG(swr.net_sales) AS avg_net_sales
    FROM SalesWithReturns swr
    JOIN customer c ON c.c_customer_sk = swr.ws_item_sk
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    GROUP BY a.ca_city
)

SELECT 
    ca.ca_city,
    fr.total_sales,
    fr.total_returns,
    fr.avg_net_sales
FROM FinalResults fr
JOIN customer_address ca ON fr.ca_city = ca.ca_city
WHERE fr.total_sales > 1000
ORDER BY fr.avg_net_sales DESC
LIMIT 10;

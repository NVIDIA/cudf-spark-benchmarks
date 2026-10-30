
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
),
AggregateSales AS (
    SELECT 
        ws_order_number,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM RankedSales
    WHERE rn = 1
    GROUP BY ws_order_number
),
ReturnData AS (
    SELECT 
        wr_order_number, 
        SUM(wr_return_amt) AS total_returns
    FROM web_returns
    GROUP BY wr_order_number
),
FinalData AS (
    SELECT 
        ags.ws_order_number,
        ags.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (ags.total_sales - COALESCE(rd.total_returns, 0)) AS net_sales
    FROM AggregateSales ags
    LEFT JOIN ReturnData rd ON ags.ws_order_number = rd.wr_order_number
)
SELECT 
    f.ws_order_number,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    CASE 
        WHEN f.total_sales <= 1000 THEN 'Low Sales'
        WHEN f.total_sales BETWEEN 1001 AND 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category,
    (SELECT COUNT(DISTINCT c.c_customer_id)
     FROM customer c
     INNER JOIN web_sales ws2 ON c.c_customer_sk = ws2.ws_bill_customer_sk
     WHERE ws2.ws_order_number = f.ws_order_number) AS distinct_customer_count
FROM FinalData f
WHERE f.net_sales > (SELECT AVG(net_sales) FROM FinalData) 
AND f.ws_order_number NOT IN (
    SELECT cr_order_number 
    FROM catalog_returns 
    WHERE cr_returned_date_sk IS NOT NULL
)
ORDER BY f.net_sales DESC
LIMIT 50;

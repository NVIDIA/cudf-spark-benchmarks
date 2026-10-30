
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MAX(ws_net_profit) AS max_profit
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 2459570 AND 2459575
    GROUP BY ws_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        sd.total_orders,
        sd.max_profit,
        RANK() OVER (ORDER BY sd.total_net_paid DESC) AS sales_rank
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL AND i.i_current_price > (
        SELECT AVG(i2.i_current_price) 
        FROM item i2 
        WHERE i2.i_class_id IN (SELECT DISTINCT i_class_id FROM item WHERE i_category = 'Soft Drink')
    )
),
TopSales AS (
    SELECT 
        fs.ws_item_sk,
        fs.total_quantity,
        fs.total_net_paid,
        fs.total_orders,
        fs.max_profit
    FROM FilteredSales fs
    WHERE fs.sales_rank <= 10
),
ReturnsData AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_returned_amt
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2459570 AND 2459575
    GROUP BY wr_item_sk
),
FinalResults AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_net_paid,
        ts.total_orders,
        ts.max_profit,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_returned_amt, 0) AS total_returned_amt,
        (ts.total_net_paid - COALESCE(rd.total_returned_amt, 0)) AS net_profit_after_returns
    FROM TopSales ts
    LEFT JOIN ReturnsData rd ON ts.ws_item_sk = rd.wr_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.total_net_paid,
    f.total_orders,
    f.max_profit,
    f.total_returned,
    f.total_returned_amt,
    f.net_profit_after_returns
FROM FinalResults f
WHERE f.net_profit_after_returns > 0
ORDER BY f.net_profit_after_returns DESC
LIMIT 5;


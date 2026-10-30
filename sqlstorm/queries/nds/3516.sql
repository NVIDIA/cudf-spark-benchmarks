
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY wr.wr_item_sk
),
SalesSummary AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity_sold,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales_value,
        MAX(sd.net_profit) AS max_net_profit
    FROM SalesData sd
    GROUP BY sd.ws_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_quantity_sold,
    ss.total_sales_value,
    COALESCE(rd.total_return_quantity, 0) AS total_returned,
    COALESCE(rd.total_return_amt, 0) AS total_returned_value,
    ss.max_net_profit
FROM SalesSummary ss
LEFT JOIN ReturnData rd ON ss.ws_item_sk = rd.wr_item_sk
WHERE ss.total_quantity_sold > 100
ORDER BY ss.max_net_profit DESC
LIMIT 10;

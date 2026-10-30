
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_profit_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
      AND ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
ReturnsData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        rd.total_returns,
        rd.total_return_value,
        sd.total_orders
    FROM SalesData sd
    LEFT JOIN ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE sd.item_profit_rank <= 10
),
FinalAnalysis AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        tsi.total_quantity,
        tsi.total_profit,
        COALESCE(tsi.total_returns, 0) AS total_returns,
        COALESCE(tsi.total_return_value, 0) AS total_return_value,
        CASE 
            WHEN tsi.total_profit > 0 THEN 'Profitable'
            WHEN tsi.total_profit = 0 THEN 'Break-Even'
            ELSE 'Unprofitable'
        END AS profitability 
    FROM TopSellingItems tsi
    JOIN item ti ON tsi.ws_item_sk = ti.i_item_sk
)
SELECT 
    fa.i_item_id,
    fa.i_item_desc,
    fa.total_quantity,
    fa.total_profit,
    fa.total_returns,
    fa.total_return_value,
    fa.profitability
FROM FinalAnalysis fa
ORDER BY fa.total_profit DESC, fa.total_quantity DESC;

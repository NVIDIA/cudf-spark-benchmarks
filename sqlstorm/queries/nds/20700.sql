
WITH 
SalesData AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers,
        MAX(ws_sales_price) AS max_price
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY ws_item_sk, ws_order_number
),
ReturnsData AS (
    SELECT
        wr_item_sk,
        wr_order_number,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_returning_customer_sk) AS unique_returning_customers
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY wr_item_sk, wr_order_number
),
SalesReturns AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_order_number,
        sd.total_net_profit,
        COALESCE(rd.total_returned, 0) AS total_returned,
        sd.unique_customers,
        rd.unique_returning_customers,
        CASE 
            WHEN sd.total_net_profit > 0 THEN 'Profitable'
            WHEN sd.total_net_profit = 0 THEN 'Break-even'
            ELSE 'Loss'
        END AS profitability_status
    FROM SalesData sd
    LEFT JOIN ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk AND sd.ws_order_number = rd.wr_order_number
),
FinalData AS (
    SELECT 
        sr.ws_item_sk,
        sr.ws_order_number,
        sr.total_net_profit,
        sr.total_returned,
        sr.unique_customers,
        sr.unique_returning_customers,
        sr.profitability_status,
        DENSE_RANK() OVER (PARTITION BY sr.profitability_status ORDER BY sr.total_net_profit DESC) AS rank
    FROM SalesReturns sr
)
SELECT 
    fd.ws_item_sk,
    fd.ws_order_number,
    fd.total_net_profit,
    fd.total_returned,
    fd.unique_customers,
    fd.unique_returning_customers,
    fd.profitability_status
FROM FinalData fd
WHERE fd.rank <= 10
UNION ALL
SELECT 
    NULL AS ws_item_sk,
    NULL AS ws_order_number,
    SUM(fd.total_net_profit) AS total_net_profit,
    SUM(fd.total_returned) AS total_returned,
    COUNT(DISTINCT fd.unique_customers) AS unique_customers,
    COUNT(DISTINCT fd.unique_returning_customers) AS unique_returning_customers,
    'Overall' AS profitability_status
FROM FinalData fd
WHERE fd.ws_item_sk IS NOT NULL
HAVING COUNT(DISTINCT fd.ws_item_sk) > 0
ORDER BY profitability_status DESC, total_net_profit DESC;

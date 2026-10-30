
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as revenue_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) as total_quantity
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(sd.ws_net_profit) AS total_net_profit,
        SUM(sd.ws_quantity) AS total_quantity,
        COUNT(DISTINCT sd.ws_sold_date_sk) AS num_sales_days
    FROM SalesData sd
    JOIN item ON sd.ws_item_sk = item.i_item_sk
    WHERE sd.revenue_rank <= 5
    GROUP BY item.i_item_id, item.i_item_desc
),
SalesInfo AS (
    SELECT
        ts.i_item_id,
        ts.i_item_desc,
        ts.total_net_profit,
        ts.total_quantity,
        CASE
            WHEN ts.total_quantity > 100 THEN 'High Volume'
            ELSE 'Low Volume'
        END AS volume_category,
        (SELECT AVG(total_net_profit) FROM TopSales WHERE total_quantity > 100) AS avg_high_volume_profit
    FROM TopSales ts
)
SELECT 
    si.i_item_id,
    si.i_item_desc,
    si.total_net_profit,
    si.volume_category,
    CASE 
        WHEN si.total_net_profit > si.avg_high_volume_profit THEN 'Above Average Profit'
        ELSE 'Below Average Profit'
    END AS profit_comparison
FROM SalesInfo si
ORDER BY si.total_net_profit DESC
LIMIT 10;

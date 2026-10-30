
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
TopSales AS (
    SELECT 
        d.d_date,
        s.total_net_profit,
        s.total_orders,
        DENSE_RANK() OVER (ORDER BY s.total_net_profit DESC) AS sales_rank
    FROM SalesCTE s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    WHERE s.total_net_profit > 10000
)
SELECT 
    da.ca_city,
    da.ca_state,
    MAX(ts.total_net_profit) AS max_net_profit,
    MIN(ts.total_orders) AS min_orders,
    COALESCE(AVG(ts.total_net_profit), 0) AS avg_net_profit
FROM TopSales ts
JOIN customer_address da ON ts.total_orders = da.ca_address_sk
WHERE ts.sales_rank < 10
GROUP BY da.ca_city, da.ca_state
HAVING MAX(ts.total_net_profit) IS NOT NULL
ORDER BY max_net_profit DESC
LIMIT 5;

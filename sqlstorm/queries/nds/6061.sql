
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20.00 AND 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_ship_date_sk,
        rs.ws_item_sk,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
),
AggregatedTotals AS (
    SELECT 
        ds.d_year,
        SUM(ts.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ts.ws_order_number) AS total_orders
    FROM 
        TopSales ts
    JOIN 
        date_dim ds ON ts.ws_ship_date_sk = ds.d_date_sk
    GROUP BY 
        ds.d_year
)
SELECT 
    at.d_year,
    at.total_profit,
    at.total_orders,
    CASE 
        WHEN at.total_orders = 0 THEN 0 
        ELSE at.total_profit / NULLIF(at.total_orders, 0) 
    END AS avg_profit_per_order
FROM 
    AggregatedTotals at
ORDER BY 
    at.d_year DESC;

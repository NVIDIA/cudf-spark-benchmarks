
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        i.i_item_desc,
        w.w_warehouse_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_revenue,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rnk
    FROM SalesData
    GROUP BY ws_item_sk
),
RankedSales AS (
    SELECT 
        a.ws_item_sk,
        a.total_orders,
        a.total_revenue,
        a.total_discount,
        a.total_profit,
        i.i_item_desc AS i_product_name,
        RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank
    FROM AggregatedSales a
    JOIN item i ON a.ws_item_sk = i.i_item_sk
)
SELECT 
    r.ws_item_sk,
    r.total_orders,
    r.total_revenue,
    r.total_discount,
    r.total_profit,
    r.i_product_name,
    r.profit_rank,
    CASE 
        WHEN r.total_profit > 500 THEN 'Low Profit'
        WHEN r.total_profit BETWEEN 200 AND 500 THEN 'Medium Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM RankedSales r
WHERE r.profit_rank <= 10
ORDER BY r.total_profit DESC;

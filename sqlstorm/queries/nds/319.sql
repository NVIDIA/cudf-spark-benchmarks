
WITH ReturnStats AS (
    SELECT
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_item_sk) AS total_items_returned
    FROM store_returns
    GROUP BY sr_returned_date_sk
), 
SalesStats AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_units_sold
    FROM web_sales
    GROUP BY ws_sold_date_sk
), 
CombinedStats AS (
    SELECT
        dd.d_date AS sales_date,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        COALESCE(rs.total_return_tax, 0) AS total_return_tax,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_units_sold, 0) AS total_units_sold
    FROM date_dim dd
    LEFT JOIN ReturnStats rs ON dd.d_date_sk = rs.sr_returned_date_sk
    LEFT JOIN SalesStats ss ON dd.d_date_sk = ss.ws_sold_date_sk
    WHERE dd.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT
    sales_date,
    total_returns,
    total_return_amt,
    total_return_tax,
    total_sales,
    total_orders,
    total_units_sold,
    (total_sales - total_return_amt) AS net_sales,
    (CASE WHEN total_orders > 0 THEN total_sales / total_orders ELSE NULL END) AS avg_order_value,
    (CASE WHEN total_units_sold > 0 THEN total_units_sold / NULLIF(total_orders, 0) ELSE NULL END) AS avg_units_per_order
FROM CombinedStats
ORDER BY sales_date;

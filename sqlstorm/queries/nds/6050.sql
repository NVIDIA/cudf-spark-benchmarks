
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
WarehouseStats AS (
    SELECT 
        w_warehouse_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM warehouse 
    JOIN web_sales ON ws_warehouse_sk = w_warehouse_sk 
    GROUP BY w_warehouse_id
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales 
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
)
SELECT 
    cs.cd_gender,
    cs.num_customers,
    cs.avg_purchase_estimate,
    cs.total_dependents,
    ws.w_warehouse_id,
    ws.total_sales,
    ws.order_count,
    ss.d_year,
    ss.total_sales AS yearly_sales,
    ss.total_profit
FROM CustomerStats cs
JOIN WarehouseStats ws ON cs.num_customers > 1000
JOIN SalesStats ss ON ss.total_sales > 1000000
ORDER BY cs.num_customers DESC, ss.d_year;

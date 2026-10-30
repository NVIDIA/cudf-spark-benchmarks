
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN ws.ws_sales_price > 100 THEN 1 ELSE 0 END) AS high_value_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
warehouse_stats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM warehouse AS w
    JOIN inventory AS inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
sales_summary AS (
    SELECT 
        CAST(d.d_date AS DATE) AS sales_date,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM date_dim AS d
    LEFT JOIN web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales AS cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales AS ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_date
),
final_report AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        ws.w_warehouse_name,
        COALESCE(cs.high_value_sales, 0) AS high_value_orders,
        cs.total_orders,
        ROUND(cs.avg_order_value, 2) AS average_order_value,
        ROUND(ws.total_inventory, 0) AS warehouse_inventory,
        ROUND(ws.avg_inventory, 0) AS avg_inventory,
        s.sales_date,
        s.total_web_sales,
        s.total_catalog_sales,
        s.total_store_sales
    FROM customer_stats AS cs
    LEFT JOIN warehouse_stats AS ws ON ws.total_inventory > 0
    LEFT JOIN sales_summary AS s ON s.sales_date = CAST('2002-10-01' AS DATE)
)
SELECT 
    *,
    CASE 
        WHEN total_web_sales > 10000 THEN 'High Performer'
        WHEN total_catalog_sales > 10000 THEN 'Catalog Favorite'
        WHEN total_store_sales > 10000 THEN 'Store Star'
        ELSE 'Needs Improvement'
    END AS performance_category
FROM final_report
WHERE (high_value_orders > 5 OR total_orders > 20)
ORDER BY average_order_value DESC, warehouse_inventory DESC;

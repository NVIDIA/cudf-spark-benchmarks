
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales_price,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM date_dim d
    JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_year, d.d_month_seq
),
customer_demographics_summary AS (
    SELECT 
        cd.cd_marital_status,
        AVG(cd.cd_dep_count) AS avg_dependencies,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_marital_status
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
),
promotion_analysis AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS orders_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_name
)
SELECT 
    s.sales_year,
    s.sales_month,
    s.total_quantity,
    s.total_sales_price,
    c.cd_marital_status,
    c.avg_dependencies,
    c.avg_purchase_estimate,
    w.w_warehouse_id,
    w.total_profit,
    p.p_promo_name,
    p.orders_count,
    p.total_sales
FROM sales_summary s
JOIN customer_demographics_summary c ON c.avg_dependencies > 2
JOIN warehouse_sales w ON w.total_profit > 5000
JOIN promotion_analysis p ON p.total_sales > 10000
ORDER BY s.sales_year, s.sales_month, w.total_profit DESC;

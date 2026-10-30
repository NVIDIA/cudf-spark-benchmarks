
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_sold_date_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent
    FROM store_sales ss
    JOIN customer_summary cs ON ss.ss_customer_sk = cs.c_customer_sk
    GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name
    ORDER BY total_spent DESC
    LIMIT 10
),
daily_performance AS (
    SELECT 
        d.d_date,
        ss.total_sales,
        ss.total_orders,
        ss.avg_order_value,
        COALESCE(tc.total_spent, 0) AS total_spent_top_customers
    FROM sales_summary ss
    LEFT JOIN top_customers tc ON ss.ws_sold_date_sk = (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = d.d_date)
    JOIN date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    d.d_date,
    d.total_sales,
    d.total_orders,
    ROUND(d.avg_order_value, 2) AS average_order_value,
    d.total_spent_top_customers,
    CASE 
        WHEN d.total_orders = 0 THEN 'No Orders'
        ELSE 'Orders Made'
    END AS order_status
FROM daily_performance d
WHERE d.total_sales > (
    SELECT AVG(total_sales) FROM sales_summary
)
ORDER BY d.d_date DESC;

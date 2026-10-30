
WITH  sales_data AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT
        sd.c_customer_sk,
        sd.total_sales,
        sd.order_count
    FROM sales_data sd
    WHERE sd.sales_rank <= 10
),
average_sales AS (
    SELECT
        AVG(total_sales) AS avg_sales,
        AVG(order_count) AS avg_orders
    FROM top_customers
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ti.total_sales AS customer_total_sales,
        ti.order_count AS customer_order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN top_customers ti ON c.c_customer_sk = ti.c_customer_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.cd_gender,
    ci.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(ci.customer_total_sales, 0) AS total_sales,
    COALESCE(ci.customer_order_count, 0) AS order_count,
    (CASE 
        WHEN ci.customer_total_sales IS NULL THEN 'No Sales'
        WHEN ci.customer_total_sales >= (SELECT avg_sales FROM average_sales) THEN 'Above Average'
        ELSE 'Below Average' 
     END) AS sales_performance
FROM customer_info ci
JOIN income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY total_sales DESC;

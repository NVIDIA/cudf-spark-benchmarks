
WITH sales_summary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS average_net_profit,
        s.s_store_name,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        d.d_month_seq
    FROM web_sales ws
    JOIN store s ON ws.ws_warehouse_sk = s.s_store_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 
    AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY ws.ws_ship_date_sk, s.s_store_name, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT 
    r.s_store_name,
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    r.order_count,
    r.total_quantity,
    r.average_net_profit,
    d.d_month_seq
FROM ranked_sales r
JOIN date_dim d ON r.ws_ship_date_sk = d.d_date_sk
WHERE r.sales_rank <= 5
ORDER BY r.s_store_name, r.sales_rank;

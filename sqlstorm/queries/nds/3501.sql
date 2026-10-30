
WITH sales_summary AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk AND d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_year, c.c_customer_id
),
ranked_sales AS (
    SELECT
        d_year,
        c_customer_id,
        total_store_sales,
        total_transactions,
        total_web_sales,
        total_web_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY total_store_sales DESC) AS store_rank,
        RANK() OVER (PARTITION BY d_year ORDER BY total_web_profit DESC) AS web_rank
    FROM sales_summary
),
customer_ranking AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN ss.ss_net_profit IS NULL THEN 0 ELSE ss.ss_net_profit END) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM customer c
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
)
SELECT
    r.d_year,
    r.c_customer_id,
    r.total_store_sales,
    r.total_transactions,
    r.total_web_sales,
    r.total_web_profit,
    r.store_rank,
    r.web_rank,
    cr.total_profit,
    cr.transaction_count
FROM ranked_sales r
JOIN customer_ranking cr ON r.c_customer_id = cr.c_customer_id
WHERE r.store_rank <= 10 OR r.web_rank <= 10
ORDER BY r.d_year, r.store_rank, r.web_rank;

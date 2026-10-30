WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2001
        AND dd.d_month_seq IN (1, 2, 3) 
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.average_profit,
    r.r_reason_desc AS return_reason,
    COUNT(sr.sr_return_quantity) AS total_returns
FROM
    top_customers tc
LEFT JOIN store_returns sr ON tc.c_customer_id = CAST(sr.sr_customer_sk AS CHAR(16))
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    tc.sales_rank <= 10
GROUP BY
    tc.c_customer_id, tc.c_first_name, tc.c_last_name, tc.total_sales, tc.order_count, tc.average_profit, r.r_reason_desc
ORDER BY
    tc.total_sales DESC;
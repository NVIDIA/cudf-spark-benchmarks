
WITH customer_orders AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
top_customers AS (
    SELECT
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.total_quantity,
        co.total_spent,
        co.order_count,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM
        customer_orders co
    WHERE
        co.total_quantity > 10
)
SELECT
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS customer_name,
    tc.total_quantity,
    tc.total_spent,
    tc.order_count,
    r.r_reason_desc AS return_reason
FROM
    top_customers tc
LEFT JOIN
    web_returns wr ON tc.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN
    reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    tc.customer_rank <= 10
ORDER BY
    tc.total_spent DESC;

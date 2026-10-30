
WITH sales_summary AS (
    SELECT
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM
        web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        w.w_warehouse_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS customer_sales,
        COUNT(DISTINCT ws.ws_order_number) AS customer_orders,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender
),
best_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.customer_sales,
        cs.customer_orders,
        cs.cd_gender
    FROM
        customer_summary cs
    WHERE
        cs.gender_rank <= 10
),
returns_summary AS (
    SELECT
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns
    FROM
        web_returns wr
    GROUP BY
        wr.wr_returning_customer_sk
)
SELECT
    cs.c_customer_sk,
    cs.customer_sales,
    cs.customer_orders,
    COALESCE(rs.total_returns, 0) AS total_returns,
    ss.total_sales,
    ss.order_count,
    ss.avg_profit
FROM
    best_customers cs
LEFT JOIN returns_summary rs ON cs.c_customer_sk = rs.wr_returning_customer_sk
JOIN sales_summary ss ON ss.w_warehouse_sk = (SELECT MIN(w.w_warehouse_sk) FROM warehouse w)
ORDER BY
    cs.customer_sales DESC
LIMIT 50;

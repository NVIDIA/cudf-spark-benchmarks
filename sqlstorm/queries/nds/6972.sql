
WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND ws.ws_net_profit > 0
    GROUP BY
        w.w_warehouse_id
),
customer_summary AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_customer_profit,
        COUNT(DISTINCT ws.ws_order_number) AS customer_order_count
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id, d.d_year
),
overall_summary AS (
    SELECT
        ss.w_warehouse_id,
        ss.total_quantity,
        ss.total_profit,
        ss.total_orders,
        SUM(cs.total_customer_profit) AS total_customer_profit,
        SUM(cs.customer_order_count) AS total_customer_orders
    FROM
        sales_summary ss
    JOIN customer_summary cs ON ss.total_orders > 0
    GROUP BY
        ss.w_warehouse_id, ss.total_quantity, ss.total_profit, ss.total_orders
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    os.total_quantity,
    os.total_profit,
    os.total_orders,
    os.total_customer_profit,
    os.total_customer_orders
FROM
    overall_summary os
JOIN warehouse w ON os.w_warehouse_id = w.w_warehouse_id
ORDER BY
    os.total_profit DESC;

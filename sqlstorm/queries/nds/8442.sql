
WITH sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_bought
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        ss.total_orders,
        ss.total_net_profit,
        ss.avg_order_value,
        ss.distinct_items_bought,
        DENSE_RANK() OVER (ORDER BY ss.total_net_profit DESC) AS customer_rank
    FROM
        customer AS cs
    JOIN
        sales_summary AS ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE
        ss.total_orders > 10
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_net_profit,
    tc.avg_order_value,
    tc.distinct_items_bought
FROM
    top_customers AS tc
WHERE
    tc.customer_rank <= 100
ORDER BY
    tc.total_net_profit DESC;

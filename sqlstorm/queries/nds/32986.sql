
WITH  sales_summary AS (
    SELECT
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
return_summary AS (
    SELECT
        wr_item_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        CD.cd_gender,
        COUNT(DISTINCT ws_order_number) AS orders,
        SUM(ws_net_paid) AS total_spent,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    GROUP BY
        c.c_customer_sk, CD.cd_gender
)
SELECT
    item.i_item_id,
    item.i_item_desc,
    COALESCE(ss.total_orders, 0) AS orders,
    COALESCE(ss.total_revenue, 0) AS revenue,
    COALESCE(rs.total_returns, 0) AS returns,
    COALESCE(rs.total_return_value, 0) AS return_value,
    cs.orders AS customer_orders,
    cs.total_spent AS customer_total_spent,
    cs.last_purchase_date
FROM
    item
LEFT JOIN
    sales_summary ss ON item.i_item_sk = ss.ws_item_sk
LEFT JOIN
    return_summary rs ON item.i_item_sk = rs.wr_item_sk
LEFT JOIN
    customer_stats cs ON cs.orders > 0
WHERE
    ss.rn <= 10
    AND (cs.orders IS NULL OR cs.total_spent > 500)
ORDER BY
    revenue DESC
LIMIT 50;


WITH sales_summary AS (
    SELECT
        CASE
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 1000 AND 5000
        AND c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY
        cd_gender
),
top_selling_items AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 1000 AND 5000
    GROUP BY
        i.i_item_id
    ORDER BY
        total_revenue DESC
    LIMIT 10
),
customer_activity AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_total,
        SUM(ws.ws_net_profit) AS net_profit
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_id
)
SELECT
    s.gender,
    s.total_sales,
    s.total_orders,
    s.unique_customers,
    t.total_quantity_sold,
    t.total_revenue,
    ca.orders_total AS total_orders_customer,
    ca.net_profit
FROM
    sales_summary s
JOIN
    top_selling_items t ON s.total_sales > 1000
LEFT JOIN
    customer_activity ca ON ca.orders_total > 5
ORDER BY
    s.total_sales DESC, 
    t.total_revenue DESC;


WITH ranked_sales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.total_net_profit,
        r.total_orders
    FROM
        ranked_sales r
    WHERE
        r.rank <= 10
),
Product_Sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_net_profit) AS total_sold_profit
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_id, i.i_product_name
)
SELECT
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ps.i_item_id,
    ps.i_product_name,
    ps.total_sold_quantity,
    ps.total_sold_profit
FROM
    top_customers tc
JOIN
    Product_Sales ps ON tc.total_net_profit > ps.total_sold_profit
ORDER BY
    tc.total_net_profit DESC, ps.total_sold_profit DESC;

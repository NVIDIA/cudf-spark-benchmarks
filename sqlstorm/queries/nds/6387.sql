
WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT
        sd.ws_item_sk,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS item_rank
    FROM
        sales_data sd
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM
        customer_sales cs
)
SELECT
    dd.d_date_id,
    ti.ws_item_sk,
    ti.item_rank,
    tc.c_customer_sk,
    tc.customer_rank,
    COUNT(ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_net_profit
FROM
    date_dim dd
JOIN
    sales_data sd ON dd.d_date_sk = sd.ws_sold_date_sk
JOIN
    top_items ti ON sd.ws_item_sk = ti.ws_item_sk
JOIN
    top_customers tc ON tc.customer_rank <= 10
LEFT JOIN
    store_sales ss ON ss.ss_sold_date_sk = sd.ws_sold_date_sk AND ss.ss_item_sk = sd.ws_item_sk
WHERE
    dd.d_month_seq BETWEEN 1 AND 6
GROUP BY
    dd.d_date_id, ti.ws_item_sk, ti.item_rank, tc.c_customer_sk, tc.customer_rank
ORDER BY
    dd.d_date_id, ti.item_rank, tc.customer_rank;

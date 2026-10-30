
WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
),
TopItems AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_profit,
        sd.total_orders,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS rank_profit,
        RANK() OVER (ORDER BY sd.total_quantity DESC) AS rank_quantity
    FROM
        SalesData sd
    JOIN
        item i ON sd.ws_item_sk = i.i_item_sk
),
CustomerData AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_net_profit) AS customer_profit,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM
        web_sales ws
    JOIN
        customer c ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.customer_profit,
        cd.orders_count,
        RANK() OVER (ORDER BY cd.customer_profit DESC) AS rank_profit,
        RANK() OVER (ORDER BY cd.orders_count DESC) AS rank_orders
    FROM
        CustomerData cd
)
SELECT
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_profit,
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.orders_count
FROM
    TopItems ti
JOIN
    TopCustomers tc ON ti.rank_profit <= 10 AND tc.rank_profit <= 10
ORDER BY
    ti.total_profit DESC, tc.customer_profit DESC;

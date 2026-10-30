WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_profit,
    t.order_count
FROM
    TopCustomers t
WHERE
    t.rank <= 10
ORDER BY
    t.total_profit DESC;
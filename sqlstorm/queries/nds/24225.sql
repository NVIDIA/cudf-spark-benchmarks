
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_net_paid_inc_tax IS NOT NULL
),
RecentSales AS (
    SELECT
        ws_item_sk,
        MAX(ws_net_paid_inc_tax) AS max_net_paid
    FROM
        RankedSales
    WHERE
        rank = 1
    GROUP BY
        ws_item_sk
),
TopItems AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(r.max_net_paid, 0) AS max_net_paid,
        ROW_NUMBER() OVER (ORDER BY COALESCE(r.max_net_paid, 0) DESC) AS item_rank
    FROM
        item i
    LEFT JOIN
        RecentSales r ON i.i_item_sk = r.ws_item_sk
    WHERE
        i.i_current_price > (SELECT AVG(i_current_price) FROM item)
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
QualifiedCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.order_count,
        cs.total_spent,
        RANK() OVER (PARTITION BY cs.order_count ORDER BY cs.total_spent DESC) AS rank_by_spent
    FROM
        CustomerStats cs
    WHERE
        cs.total_spent > 10000
)
SELECT
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    qc.order_count,
    qc.total_spent
FROM
    customer c
JOIN
    QualifiedCustomers qc ON c.c_customer_sk = qc.c_customer_sk
JOIN
    TopItems i ON qc.order_count >= i.item_rank
WHERE
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = c.c_customer_sk) = 0
    AND qc.rank_by_spent < 5
ORDER BY
    qc.total_spent DESC
LIMIT 10;

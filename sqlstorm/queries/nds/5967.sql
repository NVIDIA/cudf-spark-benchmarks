
WITH RankedSales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ss_store_sk, ss_item_sk
),
TopSellingItems AS (
    SELECT
        rs.ss_store_sk,
        rs.ss_item_sk,
        rs.total_quantity,
        rs.total_net_profit
    FROM
        RankedSales rs
    WHERE
        rs.profit_rank <= 5
),
CustomerPurchase AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        c.c_customer_sk
)
SELECT
    c.c_customer_id,
    cs.total_spent,
    cs.total_orders,
    tsi.total_quantity,
    tsi.total_net_profit,
    i.i_product_name,
    w.w_warehouse_name
FROM
    CustomerPurchase cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
JOIN TopSellingItems tsi ON tsi.ss_store_sk = c.c_current_addr_sk
JOIN item i ON tsi.ss_item_sk = i.i_item_sk
JOIN warehouse w ON tsi.ss_store_sk = w.w_warehouse_sk
WHERE
    cs.total_spent > 1000
ORDER BY
    cs.total_spent DESC;

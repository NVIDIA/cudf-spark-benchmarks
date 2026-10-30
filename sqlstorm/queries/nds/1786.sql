
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_ship_date_sk,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM
        web_sales
    WHERE
        ws_net_profit IS NOT NULL
),
CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
TopItems AS (
    SELECT
        item.i_item_sk,
        item.i_product_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COALESCE(MAX(ws.ws_sales_price), 0) AS highest_sales_price
    FROM
        item
    LEFT JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY
        item.i_item_sk, item.i_product_name
    HAVING
        COALESCE(SUM(ws.ws_net_profit), 0) > 1000
)
SELECT
    ca.ca_address_id,
    c.c_first_name,
    c.c_last_name,
    ti.i_product_name,
    ti.total_profit,
    ti.highest_sales_price,
    cr.total_returns,
    cr.total_return_amount
FROM
    customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
JOIN TopItems ti ON c.c_current_cdemo_sk = ti.i_item_sk
WHERE
    (cr.total_returns > 0 OR cr.total_return_amount IS NULL)
AND
    EXISTS (
        SELECT 1
        FROM RankedSales rs
        WHERE rs.ws_item_sk = ti.i_item_sk
        AND rs.profit_rank = 1
    )
ORDER BY
    ti.total_profit DESC,
    cr.total_return_amount ASC;

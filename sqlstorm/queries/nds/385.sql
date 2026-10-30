
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
AggregateSales AS (
    SELECT
        s.s_store_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_item_sk) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        store s
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY
        s.s_store_sk
)
SELECT
    a.s_store_sk,
    a.total_net_profit,
    a.total_sales,
    a.avg_net_profit,
    ca.ca_city,
    ca.ca_state,
    d.d_year,
    (SELECT COUNT(*) FROM RankedSales rs WHERE rs.ws_item_sk = a.s_store_sk AND rs.profit_rank <= 10) AS top_profit_products
FROM
    AggregateSales a
JOIN customer_address ca ON ca.ca_address_sk = (
        SELECT c.c_current_addr_sk
        FROM customer c
        WHERE c.c_customer_sk = (SELECT MIN(ws_bill_customer_sk) FROM web_sales ws)
        )
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
WHERE
    a.total_net_profit > (
        SELECT AVG(total_net_profit)
        FROM AggregateSales
    )
ORDER BY
    a.total_net_profit DESC
LIMIT 10;

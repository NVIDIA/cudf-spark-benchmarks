
WITH RankedSales AS (
    SELECT ws.ws_item_sk,
           ws.ws_sold_date_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit,
           DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
),
TopSales AS (
    SELECT rs.ws_item_sk,
           rs.total_quantity,
           rs.total_profit,
           i.i_item_desc,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    JOIN web_sales ws ON rs.ws_item_sk = ws.ws_item_sk AND rs.ws_sold_date_sk = ws.ws_sold_date_sk
    WHERE rs.rank <= 10
    GROUP BY rs.ws_item_sk, rs.total_quantity, rs.total_profit, i.i_item_desc
)
SELECT ts.i_item_desc,
       ts.total_quantity,
       ts.total_profit,
       ts.total_orders,
       ROW_NUMBER() OVER (ORDER BY ts.total_profit DESC) AS sales_rank
FROM TopSales ts
ORDER BY ts.total_profit DESC;

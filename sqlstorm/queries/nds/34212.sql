
WITH  sales_cte AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 1000
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2022 AND d_month_seq BETWEEN 1 AND 3
        )
    GROUP BY
        cs_sold_date_sk, cs_item_sk
),
total_sales AS (
    SELECT
        item.i_item_id,
        SUM(s.total_quantity) AS quantity,
        SUM(s.total_profit) AS profit
    FROM
        sales_cte s
    JOIN
        item item ON s.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id
),
top_5_items AS (
    SELECT
        item.i_item_id,
        ts.quantity,
        ts.profit,
        ROW_NUMBER() OVER (ORDER BY ts.profit DESC) AS rank
    FROM
        total_sales ts
    JOIN
        item item ON ts.i_item_id = item.i_item_id
)
SELECT 
    COALESCE(t5.i_item_id, 'No sales') AS item_id,
    COALESCE(t5.quantity, 0) AS total_quantity,
    COALESCE(t5.profit, 0.00) AS total_profit
FROM
    (SELECT 1 AS level UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS seq
LEFT JOIN
    top_5_items t5 ON seq.level = t5.rank
ORDER BY 
    seq.level;

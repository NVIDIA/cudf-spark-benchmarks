
WITH  sales_cte AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales AS ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY
        ws.ws_item_sk
    HAVING
        SUM(ws.ws_net_profit) > 5000
    UNION ALL
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(cs.cs_order_number) AS order_count
    FROM
        catalog_sales AS cs
    WHERE
        cs.cs_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY
        cs.cs_item_sk
    HAVING
        SUM(cs.cs_net_profit) > 5000
),
ranked_sales AS (
    SELECT
        s.ws_item_sk,
        s.total_profit,
        s.order_count,
        RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank
    FROM
        sales_cte AS s
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    r.total_profit,
    r.order_count,
    r.profit_rank,
    COALESCE(CAST(NULLIF(MAX(sr.sr_return_quantity), 0) AS INTEGER), 0) AS max_returned_quantity,
    COALESCE(CAST(NULLIF(MAX(cr.cr_return_quantity), 0) AS INTEGER), 0) AS max_catalog_returned_quantity
FROM
    ranked_sales AS r
LEFT JOIN item AS i ON i.i_item_sk = r.ws_item_sk
LEFT JOIN store_returns AS sr ON sr.sr_item_sk = r.ws_item_sk
LEFT JOIN catalog_returns AS cr ON cr.cr_item_sk = r.ws_item_sk
WHERE
    r.profit_rank <= 10
GROUP BY
    i.i_item_id,
    i.i_item_desc,
    r.total_profit,
    r.order_count,
    r.profit_rank
ORDER BY
    r.profit_rank;

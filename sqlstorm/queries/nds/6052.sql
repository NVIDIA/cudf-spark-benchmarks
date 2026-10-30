
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1000 AND 10000
),
top_selling_items AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
high_profit_items AS (
    SELECT
        item.i_item_id,
        item.i_product_name,
        item.i_brand,
        item.i_class,
        ranked_sales.ws_quantity,
        ranked_sales.ws_net_profit,
        top_selling_items.total_returns
    FROM
        ranked_sales
    JOIN
        item ON ranked_sales.ws_item_sk = item.i_item_sk
    LEFT JOIN
        top_selling_items ON ranked_sales.ws_item_sk = top_selling_items.sr_item_sk
    WHERE
        ranked_sales.profit_rank <= 10
)
SELECT
    hpi.i_item_id,
    hpi.i_product_name,
    hpi.i_brand,
    hpi.i_class,
    hpi.ws_quantity,
    hpi.ws_net_profit,
    COALESCE(hpi.total_returns, 0) AS total_returns
FROM
    high_profit_items hpi
ORDER BY
    hpi.ws_net_profit DESC;

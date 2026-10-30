
WITH sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
top_sales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        sd.avg_sales_price,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name
    FROM
        sales_data sd
    JOIN
        item i ON sd.ws_item_sk = i.i_item_sk
    JOIN
        web_returns wr ON sd.ws_item_sk = wr.wr_item_sk
    JOIN
        customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE
        sd.sales_rank <= 10
)
SELECT
    ts.ws_item_sk,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_net_paid,
    COALESCE(ts.avg_sales_price, 0) AS avg_sales_price,
    CONCAT(ts.c_first_name, ' ', ts.c_last_name) AS customer_name
FROM
    top_sales ts
LEFT JOIN
    store_sales ss ON ts.ws_item_sk = ss.ss_item_sk
WHERE
    ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim 
        WHERE d_year = 2022 AND d_moy IN (11, 12)
    )
    OR ss.ss_sold_date_sk IS NULL
ORDER BY
    total_net_paid DESC;

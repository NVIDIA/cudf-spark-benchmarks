
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY
        ws.ws_item_sk
),
TopItems AS (
    SELECT
        ri.ws_item_sk,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        RankedSales ri
    JOIN
        web_sales ws ON ri.ws_item_sk = ws.ws_item_sk
    WHERE
        ri.sales_rank <= 10
    GROUP BY
        ri.ws_item_sk
)
SELECT
    ti.ws_item_sk,
    ti.customer_count,
    ti.avg_net_profit,
    i.i_item_desc,
    i.i_brand,
    i.i_category
FROM
    TopItems ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
ORDER BY
    ti.avg_net_profit DESC;

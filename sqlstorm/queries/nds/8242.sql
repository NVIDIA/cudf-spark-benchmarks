
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND i.i_current_price > 0
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk
),
TopItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        sd.avg_net_profit,
        RANK() OVER (ORDER BY sd.total_sales_amount DESC) AS sales_rank
    FROM
        SalesData sd
)
SELECT
    ti.ws_item_sk,
    ti.total_quantity_sold,
    ti.total_sales_amount,
    ti.avg_net_profit,
    i.i_item_desc,
    i.i_brand,
    i.i_category
FROM
    TopItems ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE
    ti.sales_rank <= 10
ORDER BY
    ti.total_sales_amount DESC;


WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2022
    GROUP BY
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM
        SalesData sd
)
SELECT
    item.i_item_id,
    item.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.rank
FROM
    TopSellingItems ts
JOIN
    item ON ts.ws_item_sk = item.i_item_sk
WHERE
    ts.rank <= 10
ORDER BY
    ts.rank;

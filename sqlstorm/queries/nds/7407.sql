
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT
        sd.ws_item_sk,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS item_rank
    FROM
        SalesData sd
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ti.item_rank,
    sd.total_sales,
    sd.total_quantity
FROM
    TopItems ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN
    SalesData sd ON ti.ws_item_sk = sd.ws_item_sk
WHERE
    ti.item_rank <= 10
ORDER BY
    ti.item_rank;

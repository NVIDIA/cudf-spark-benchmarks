
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE dd.d_year = 2022 
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
RankedSales AS (
    SELECT
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.total_net_sales,
        RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_net_sales DESC) AS sales_rank
    FROM SalesData sd
),
TopSellingItems AS (
    SELECT
        d.d_date AS date,
        i.i_item_id,
        i.i_item_desc,
        ts.total_quantity,
        ts.total_sales,
        ts.total_discount,
        ts.total_net_sales,
        ts.sales_rank
    FROM RankedSales ts
    JOIN date_dim d ON ts.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ts.ws_item_sk = i.i_item_sk
    WHERE ts.sales_rank <= 5
)
SELECT
    t.date,
    t.i_item_id,
    t.i_item_desc,
    t.total_quantity,
    t.total_sales,
    t.total_discount,
    t.total_net_sales
FROM TopSellingItems t
ORDER BY t.date, t.sales_rank;


WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2022
        AND cd.cd_gender = 'F'
    GROUP BY
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_sales
    FROM
        RankedSales ri
    WHERE
        ri.sales_rank <= 10
)
SELECT
    i.i_item_id,
    i.i_product_name,
    tsi.total_quantity,
    tsi.total_sales
FROM
    item i
JOIN
    TopSellingItems tsi ON i.i_item_sk = tsi.ws_item_sk
ORDER BY
    tsi.total_sales DESC;

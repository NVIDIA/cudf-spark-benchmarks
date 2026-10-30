
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
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_marital_status = 'M'
    GROUP BY
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank <= 5
)
SELECT
    it.i_item_id,
    it.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales,
    (tsi.total_sales / NULLIF(tsi.total_quantity, 0)) AS avg_price_per_unit
FROM
    TopSellingItems tsi
JOIN
    item it ON tsi.ws_item_sk = it.i_item_sk
ORDER BY
    tsi.total_sales DESC;

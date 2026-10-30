WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2001
    GROUP BY
        ws.ws_item_sk, ws.ws_sold_date_sk
),
TopSellingItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity_sold,
        rs.total_sales
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank <= 10
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity_sold,
    tsi.total_sales,
    ca.ca_city,
    ca.ca_state
FROM
    TopSellingItems tsi
JOIN
    item i ON tsi.ws_item_sk = i.i_item_sk
JOIN
    customer c ON c.c_current_cdemo_sk = i.i_item_sk 
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY
    tsi.total_sales DESC;
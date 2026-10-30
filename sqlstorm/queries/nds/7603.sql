
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws.ws_item_sk
),
TopSales AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM
        RankedSales rs
    JOIN
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE
        rs.rank <= 10
)
SELECT
    ca.ca_country,
    SUM(ts.total_sales) AS country_sales,
    COUNT(DISTINCT ts.ws_item_sk) AS unique_items_sold
FROM
    TopSales ts
JOIN
    customer c ON ts.ws_item_sk = c.c_current_addr_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY
    ca.ca_country
ORDER BY
    country_sales DESC;

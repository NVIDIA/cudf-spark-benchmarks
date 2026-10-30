
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_credit_rating IN ('Average', 'Good')
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk
),
TopItems AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.total_sold) AS total_units_sold,
        SUM(sd.total_revenue) AS total_revenue
    FROM
        SalesData sd
    GROUP BY
        sd.ws_item_sk
    ORDER BY
        total_revenue DESC
    LIMIT 10
)
SELECT
    ti.ws_item_sk,
    i.i_item_desc,
    ti.total_units_sold,
    ti.total_revenue,
    (SELECT COUNT(DISTINCT ws.ws_order_number)
     FROM web_sales ws
     WHERE ws.ws_item_sk = ti.ws_item_sk AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(ws_sold_date_sk) FROM web_sales) AND (SELECT MAX(ws_sold_date_sk) FROM web_sales)) AS order_count,
    dd.d_date AS report_date
FROM
    TopItems ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN
    date_dim dd ON dd.d_year = 2023
ORDER BY
    ti.total_revenue DESC;


WITH SalesDetails AS (
    SELECT
        ws.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        SUM(ws.ws_ext_tax) AS total_tax,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 AND
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY
        ws.ws_item_sk
),
TopItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_revenue,
        sd.total_tax,
        sd.average_profit,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesDetails sd
)
SELECT
    ti.ws_item_sk,
    i.i_item_desc,
    ti.total_sales,
    ti.total_revenue,
    ti.total_tax,
    ti.average_profit
FROM
    TopItems ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE
    ti.sales_rank <= 10
ORDER BY
    ti.total_sales DESC;

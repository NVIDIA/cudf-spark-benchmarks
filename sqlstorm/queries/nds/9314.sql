
WITH SalesData AS (
    SELECT
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(cs_order_number) AS total_orders,
        AVG(cs_sales_price) AS average_price,
        SUM(cs_quantity) AS total_quantity
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        cs_item_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopItems AS (
    SELECT
        sd.cs_item_sk,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM
        SalesData sd
    WHERE
        sd.total_sales > 1000
)
SELECT
    ti.cs_item_sk,
    ti.total_sales,
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.order_count,
    cs.total_spent
FROM
    TopItems ti
JOIN
    CustomerStats cs ON cs.order_count > 5
ORDER BY
    ti.total_sales DESC, cs.total_spent DESC
LIMIT 50;

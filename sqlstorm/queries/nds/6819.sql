
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
        AND i.i_current_price > 0
    GROUP BY
        ws.ws_item_sk
),
TopSales AS (
    SELECT *
    FROM SalesData
    WHERE sales_rank <= 10
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ts.total_quantity) AS total_quantity,
        SUM(ts.total_sales) AS total_sales
    FROM
        TopSales ts
    JOIN
        customer c ON ts.ws_item_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cd.total_quantity) AS total_quantity,
    SUM(cd.total_sales) AS total_sales,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count
FROM
    CustomerDemographics cd
JOIN
    customer c ON cd.total_quantity = c.c_customer_sk
GROUP BY
    cd.cd_gender, cd.cd_marital_status
ORDER BY
    total_sales DESC;

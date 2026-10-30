
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT
        rs.ws_item_sk,
        i.i_item_desc,
        i.i_current_price,
        rs.total_quantity,
        rs.total_sales
    FROM
        RankedSales rs
    JOIN
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE
        rs.sales_rank <= 10
),
CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM
        catalog_returns
    WHERE
        cr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY
        cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT
    td.ws_item_sk,
    ti.i_item_desc,
    ti.i_current_price,
    td.total_quantity,
    td.total_sales,
    cr.total_returned,
    cr.return_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM
    TopSellingItems td
LEFT JOIN
    CustomerReturns cr ON td.ws_item_sk = cr.cr_returning_customer_sk
JOIN
    CustomerDemographics cd ON cd.customer_count > 10
JOIN
    item ti ON td.ws_item_sk = ti.i_item_sk
WHERE
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    AND (cr.total_returned > 20 OR cr.total_returned IS NULL)
ORDER BY
    td.total_sales DESC;


WITH RankedSales AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS price_rank
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
SalesSummary AS (
    SELECT
        i_item_id,
        SUM(cs_sales_price) AS total_sales,
        AVG(cs_sales_price) AS avg_sales_price,
        COUNT(cs_order_number) AS total_orders
    FROM
        RankedSales
    JOIN item ON RankedSales.cs_item_sk = item.i_item_sk
    WHERE
        price_rank = 1
    GROUP BY
        i_item_id
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws_ext_sales_price) AS total_web_sales
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.total_web_sales,
        DENSE_RANK() OVER (ORDER BY cd.total_web_sales DESC) AS sales_rank
    FROM
        CustomerDetails cd
    JOIN customer c ON cd.c_customer_id = c.c_customer_id
    WHERE
        cd.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerDetails)
)
SELECT
    i.i_item_id,
    ss.total_sales,
    ss.avg_sales_price,
    hvc.c_customer_id,
    hvc.total_web_sales
FROM
    SalesSummary ss
JOIN item i ON ss.i_item_id = i.i_item_id
JOIN HighValueCustomers hvc ON ss.total_sales > 1000
WHERE
    hvc.sales_rank <= 10
ORDER BY
    ss.total_sales DESC, hvc.total_web_sales DESC;

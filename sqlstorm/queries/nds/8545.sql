
WITH SalesAggregate AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(ws_order_number) AS order_count,
        d_year,
        d_month_seq
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY
        ws_item_sk, d_year, d_month_seq
),
CustomerStats AS (
    SELECT
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS unique_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM
        customer_demographics cd
    JOIN
        customer c ON cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY
        cd_demo_sk
),
SalesDetails AS (
    SELECT
        sa.ws_item_sk,
        sa.total_sales,
        sa.total_discount,
        cs.unique_customers,
        cs.avg_purchase_estimate,
        cs.avg_dep_count
    FROM
        SalesAggregate sa
    LEFT JOIN
        CustomerStats cs ON sa.ws_item_sk = cs.cd_demo_sk
)
SELECT
    sd.ws_item_sk,
    sd.total_sales,
    sd.total_discount,
    sd.unique_customers,
    sd.avg_purchase_estimate,
    sd.avg_dep_count,
    RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
FROM
    SalesDetails sd
WHERE
    sd.total_sales > 100000
ORDER BY
    sales_rank
LIMIT 10;


WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        c.c_customer_sk
),
FrequentCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_quantity,
        cs.total_sales,
        cs.order_count,
        cs.total_discount,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential
    FROM
        CustomerStats cs
    JOIN
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE
        cs.order_count > 5
),
SalesTrends AS (
    SELECT
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS annual_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
)
SELECT
    f.c_customer_sk,
    f.total_quantity,
    f.total_sales,
    f.order_count,
    f.total_discount,
    f.cd_gender,
    f.cd_marital_status,
    f.hd_buy_potential,
    s.d_year,
    s.annual_sales,
    s.total_orders
FROM
    FrequentCustomers f
JOIN
    SalesTrends s ON f.total_sales > (SELECT AVG(total_sales) FROM CustomerStats)
ORDER BY
    f.total_sales DESC, s.d_year DESC;

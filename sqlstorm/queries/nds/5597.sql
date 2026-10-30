
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE
        cs.order_count > 5
),
SalesByTime AS (
    SELECT
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY
        dd.d_year, dd.d_month_seq
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales AS customer_total_sales,
    sbt.d_year,
    sbt.d_month_seq,
    sbt.monthly_sales
FROM
    TopCustomers tc
JOIN
    SalesByTime sbt ON tc.total_sales > sbt.monthly_sales
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC, sbt.d_year, sbt.d_month_seq;

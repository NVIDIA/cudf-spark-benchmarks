
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT wr.wr_order_number) AS returns_count,
        COALESCE(NULLIF(SUM(ws.ws_ext_discount_amt), 0), 1) AS discount_adjusted,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        order_count,
        returns_count,
        discount_adjusted
    FROM
        CustomerSales
    WHERE
        sales_rank <= 10
)
SELECT
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    tc.total_sales,
    tc.order_count,
    tc.returns_count,
    (tc.total_sales / NULLIF(tc.discount_adjusted, 0)) AS adjusted_sales,
    DENSE_RANK() OVER (ORDER BY tc.total_sales DESC) AS sales_dense_rank
FROM
    TopCustomers tc
ORDER BY
    tc.total_sales DESC

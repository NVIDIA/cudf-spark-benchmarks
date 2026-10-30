
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 
        AND d.d_moy BETWEEN 1 AND 3
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
TopCustomers AS (
    SELECT
        c.customer_sk,
        c.first_name,
        c.last_name,
        cs.total_web_sales,
        cs.total_orders,
        cs.avg_net_profit,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    JOIN
        (SELECT DISTINCT c_customer_sk AS customer_sk, c_first_name AS first_name, c_last_name AS last_name
         FROM customer) c ON cs.c_customer_sk = c.customer_sk
)
SELECT
    tc.first_name,
    tc.last_name,
    tc.total_web_sales,
    tc.total_orders,
    tc.avg_net_profit
FROM
    TopCustomers tc
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_web_sales DESC;


WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS total_purchases,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_sales_price * ws.ws_quantity ELSE 0 END) AS total_spent,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM
        CustomerStats
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.total_purchases,
    c.total_spent,
    c.total_orders
FROM
    TopCustomers c
WHERE
    c.rank <= 10
ORDER BY
    c.rank;

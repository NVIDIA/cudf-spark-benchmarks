
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT
        ws_bill_customer_sk,
        total_sales,
        order_count
    FROM
        RankedSales
    WHERE
        sales_rank <= 10
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        tc.total_sales,
        tc.order_count
    FROM
        TopCustomers tc
    JOIN customer c ON c.c_customer_sk = tc.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.ca_city,
    cd.ca_state,
    cd.total_sales,
    cd.order_count,
    DENSE_RANK() OVER (ORDER BY cd.total_sales DESC) AS ranking
FROM
    CustomerDetails cd
ORDER BY
    cd.total_sales DESC;

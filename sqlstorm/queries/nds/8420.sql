
WITH RankedSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        r.c_customer_id,
        r.total_sales,
        r.order_count
    FROM
        RankedSales r
    WHERE
        r.rank <= 10
)
SELECT
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM
    TopCustomers tc
JOIN
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY
    tc.total_sales DESC;


WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'M'
    GROUP BY
        c.c_customer_id
),
top_sales AS (
    SELECT
        c.c_customer_id,
        s.total_sales,
        s.order_count,
        s.avg_sales_price,
        s.max_sales_price,
        s.min_sales_price
    FROM
        sales_summary s
    JOIN
        customer c ON s.c_customer_id = c.c_customer_id
    WHERE
        s.sales_rank <= 10
)
SELECT
    ts.c_customer_id,
    ts.total_sales,
    ts.order_count,
    ts.avg_sales_price,
    ts.max_sales_price,
    ts.min_sales_price,
    ca.ca_city,
    ca.ca_state,
    dd.d_month_seq,
    dd.d_year
FROM
    top_sales ts
JOIN
    customer c ON ts.c_customer_id = c.c_customer_id
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    date_dim dd ON dd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
ORDER BY
    ts.total_sales DESC;

WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        cd.cd_gender = 'F'
        AND dd.d_year = 2000
        AND dd.d_moy IN (5, 6) 
    GROUP BY
        ws.ws_sold_date_sk
),
average_sales AS (
    SELECT
        AVG(total_sales) AS avg_sales,
        AVG(total_quantity) AS avg_quantity,
        COUNT(*) AS sales_days
    FROM
        sales_data
)
SELECT
    dd.d_month_seq AS month,
    COALESCE(sd.total_quantity, 0) AS quantity,
    COALESCE(sd.total_sales, 0) AS sales,
    avg_sales,
    avg_quantity,
    sd.total_orders
FROM
    date_dim dd
LEFT JOIN
    sales_data sd ON dd.d_date_sk = sd.ws_sold_date_sk
CROSS JOIN
    average_sales
WHERE
    dd.d_year = 2000
    AND dd.d_moy IN (5, 6) 
ORDER BY
    dd.d_date_sk;
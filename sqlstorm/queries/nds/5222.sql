
WITH sales_summary AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY
        d.d_year, d.d_month_seq
)
SELECT
    ss.year,
    ss.month,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_profit,
    ss.unique_customers,
    RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
FROM
    sales_summary ss
WHERE
    ss.total_quantity > 1000
ORDER BY
    ss.year, ss.month;

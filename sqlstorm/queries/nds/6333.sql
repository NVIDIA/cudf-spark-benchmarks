
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM
        web_sales ws
    INNER JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        d.d_year BETWEEN 2022 AND 2023
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        ws.ws_sold_date_sk
),
MonthlySales AS (
    SELECT
        DATE_TRUNC('month', d.d_date) AS month,
        SUM(sd.total_quantity) AS month_total_quantity,
        SUM(sd.total_revenue) AS month_total_revenue
    FROM
        SalesData sd
    INNER JOIN
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        month
)
SELECT
    month,
    month_total_quantity,
    month_total_revenue,
    LAG(month_total_revenue) OVER (ORDER BY month) AS prev_month_revenue,
    (month_total_revenue - LAG(month_total_revenue) OVER (ORDER BY month)) AS revenue_change,
    (month_total_revenue / NULLIF(LAG(month_total_revenue) OVER (ORDER BY month), 0)) * 100 AS revenue_change_percentage
FROM
    MonthlySales
ORDER BY
    month DESC
LIMIT 12;

WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2000
    GROUP BY
        d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ss.total_quantity) AS total_quantity_sold,
        SUM(ss.total_sales) AS total_sales_amount
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        sales_summary ss ON ss.d_year IN (1998, 1999, 2000)  
    GROUP BY
        cd.cd_gender
)
SELECT
    cs.cd_gender,
    cs.customer_count,
    cs.total_quantity_sold,
    cs.total_sales_amount,
    RANK() OVER (ORDER BY cs.total_sales_amount DESC) AS sales_rank
FROM
    customer_summary cs
ORDER BY
    cs.total_sales_amount DESC;
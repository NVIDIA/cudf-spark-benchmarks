
WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY ws.ws_sold_date_sk
),
average_sales AS (
    SELECT
        avg(total_quantity) AS avg_quantity,
        avg(total_sales) AS avg_sales,
        avg(total_discount) AS avg_discount,
        avg(total_tax) AS avg_tax
    FROM sales_data
),
sales_summary AS (
    SELECT
        dd.d_month_seq,
        dd.d_year,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.total_tax,
        avg.avg_quantity,
        avg.avg_sales,
        avg.avg_discount,
        avg.avg_tax
    FROM sales_data sd
    JOIN date_dim dd ON sd.ws_sold_date_sk = dd.d_date_sk
    JOIN average_sales avg
    ON 1=1
)
SELECT 
    ss.d_month_seq,
    ss.d_year,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.total_tax,
    ss.avg_quantity,
    ss.avg_sales,
    ss.avg_discount,
    ss.avg_tax,
    CASE
        WHEN ss.total_sales > ss.avg_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM sales_summary ss
ORDER BY ss.d_year, ss.d_month_seq;

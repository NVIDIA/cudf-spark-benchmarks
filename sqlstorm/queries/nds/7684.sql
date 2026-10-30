
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_sales_price) AS average_sales_price,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM
        store_sales ss
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq
),
customer_summary AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS gender_marital_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_per_demographic
    FROM
        customer_demographics cd
    JOIN
        store_sales ss ON cd.cd_demo_sk = ss.ss_cdemo_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    s.d_year,
    s.d_quarter_seq,
    s.d_month_seq,
    s.total_net_profit,
    s.total_sales,
    s.average_sales_price,
    s.total_quantity_sold,
    c.cd_gender,
    c.cd_marital_status,
    c.gender_marital_net_profit,
    c.sales_per_demographic
FROM
    sales_summary s
JOIN
    customer_summary c ON s.total_sales > 0
ORDER BY
    s.d_year DESC,
    s.d_quarter_seq DESC,
    c.cd_gender,
    c.cd_marital_status;


WITH sales_data AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS average_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM
        store_sales ss
        JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        w.w_warehouse_name, d.d_year
),
demographics_data AS (
    SELECT
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM
        customer_demographics cd
    GROUP BY
        cd.cd_gender
),
final_report AS (
    SELECT
        s.w_warehouse_name,
        s.d_year,
        s.total_sales,
        s.average_profit,
        s.transaction_count,
        d.cd_gender,
        d.average_purchase_estimate
    FROM
        sales_data s
        LEFT JOIN demographics_data d ON s.total_sales > d.average_purchase_estimate
)
SELECT
    w.w_warehouse_name,
    f.d_year,
    f.total_sales,
    f.average_profit,
    f.transaction_count,
    f.cd_gender,
    f.average_purchase_estimate
FROM
    final_report f
    JOIN warehouse w ON f.w_warehouse_name = w.w_warehouse_name
ORDER BY
    f.total_sales DESC, f.average_profit DESC;

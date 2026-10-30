
WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        AVG(CASE WHEN cd_gender = 'M' THEN ss.ss_ext_sales_price ELSE 0 END) AS avg_sales_men,
        AVG(CASE WHEN cd_gender = 'F' THEN ss.ss_ext_sales_price ELSE 0 END) AS avg_sales_women
    FROM
        store_sales ss
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2022
    GROUP BY
        ss.ss_sold_date_sk, ss.ss_store_sk
),
store_sales_summary AS (
    SELECT
        sd.ss_store_sk,
        SUM(sd.total_sales) AS yearly_sales,
        SUM(sd.total_profit) AS yearly_profit,
        COUNT(sd.unique_customers) AS total_unique_customers,
        AVG(sd.avg_sales_men) AS avg_sales_per_men,
        AVG(sd.avg_sales_women) AS avg_sales_per_women
    FROM
        sales_data sd
    GROUP BY
        sd.ss_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_country,
    ss.yearly_sales,
    ss.yearly_profit,
    ss.total_unique_customers,
    ss.avg_sales_per_men,
    ss.avg_sales_per_women
FROM
    store s
JOIN
    store_sales_summary ss ON s.s_store_sk = ss.ss_store_sk
ORDER BY
    ss.yearly_sales DESC
LIMIT 10;

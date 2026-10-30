
WITH sales_summary AS (
    SELECT
        CAST(d.d_date AS DATE) AS sales_date,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        i_category AS product_category
    FROM
        store_sales
    JOIN
        date_dim d ON ss_sold_date_sk = d.d_date_sk
    JOIN
        item i ON ss_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        d.d_date, i_category
),
customer_data AS (
    SELECT
        cd_gender,
        hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    GROUP BY
        cd_gender, hd_income_band_sk
),
product_performance AS (
    SELECT
        p.p_promo_name,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_sales_price) AS total_revenue
    FROM
        web_sales ws
    JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY
        p.p_promo_name
),
final_report AS (
    SELECT
        ss.sales_date,
        ss.total_sales,
        ss.unique_customers,
        cd.cd_gender,
        cd.hd_income_band_sk,
        pp.p_promo_name AS promo_name,
        pp.orders_count,
        pp.total_revenue
    FROM
        sales_summary ss
    LEFT JOIN
        customer_data cd ON 1=1
    LEFT JOIN
        product_performance pp ON 1=1
)

SELECT
    sales_date,
    total_sales,
    unique_customers,
    cd_gender,
    hd_income_band_sk,
    promo_name,
    orders_count,
    total_revenue,
    ROW_NUMBER() OVER (PARTITION BY sales_date ORDER BY total_sales DESC) AS sales_rank
FROM
    final_report
ORDER BY
    sales_date, total_sales DESC;

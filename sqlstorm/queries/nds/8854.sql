
WITH ranked_sales AS (
    SELECT
        s.s_store_id,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_sales_price) AS total_sales_revenue,
        DENSE_RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_quantity) DESC) AS sales_rank
    FROM
        store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31'
        )
    GROUP BY
        s.s_store_id, i.i_item_id
),
top_selling_items AS (
    SELECT
        rs.s_store_id,
        rs.i_item_id,
        rs.total_quantity_sold,
        rs.total_sales_revenue
    FROM
        ranked_sales rs
    WHERE
        rs.sales_rank <= 5
),
customer_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        h.hd_income_band_sk
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
)
SELECT
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    tsi.s_store_id,
    tsi.i_item_id,
    tsi.total_quantity_sold,
    tsi.total_sales_revenue
FROM
    top_selling_items tsi
JOIN customer_info ci ON tsi.total_sales_revenue > ci.cd_purchase_estimate
ORDER BY
    tsi.total_sales_revenue DESC;

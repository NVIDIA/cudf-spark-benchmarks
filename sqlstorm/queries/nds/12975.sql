
WITH sales_summary AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity
    FROM
        store_sales
    GROUP BY
        ss_store_sk,
        ss_item_sk
),
top_sales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        total_sales,
        total_quantity,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    s_store_name,
    i_item_id,
    ts.total_sales,
    ts.total_quantity
FROM
    store st
JOIN
    top_sales ts ON st.s_store_sk = ts.ss_store_sk
JOIN
    item i ON ts.ss_item_sk = i.i_item_sk
WHERE
    ts.sales_rank <= 10
ORDER BY
    st.s_store_name,
    ts.total_sales DESC;

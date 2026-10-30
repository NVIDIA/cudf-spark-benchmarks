
WITH  sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY
        ws_item_sk
),
item_details AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand,
        COALESCE(z.ib_lower_bound, 0) AS income_lower,
        COALESCE(z.ib_upper_bound, 100000000) AS income_upper
    FROM
        item
    LEFT JOIN
        household_demographics AS h ON h.hd_demo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_credit_rating = 'A')
    LEFT JOIN
        income_band AS z ON z.ib_income_band_sk = h.hd_income_band_sk
    WHERE
        i_current_price IS NOT NULL
),
sales_trend AS (
    SELECT
        d.d_date,
        COUNT(*) AS sales_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_sales
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2022 AND d.d_moy IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_year = 2021)
    GROUP BY
        d.d_date
)
SELECT
    s.total_sales,
    s.total_revenue,
    i.i_item_desc,
    i.i_brand,
    CASE
        WHEN s.total_revenue IS NULL THEN 'No Sales'
        WHEN s.total_sales > 1000 THEN 'High Volume'
        WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_category,
    t.d_date,
    t.sales_count,
    t.avg_sales,
    RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
FROM
    sales_data s
JOIN
    item_details i ON s.ws_item_sk = i.i_item_sk
LEFT JOIN
    sales_trend t ON t.sales_count = (SELECT MAX(sales_count) FROM sales_trend)
WHERE
    (i.income_lower + i.income_upper) IS NOT NULL
    AND i.i_current_price > (SELECT AVG(i_current_price) FROM item)
ORDER BY
    revenue_rank,
    sales_category DESC;

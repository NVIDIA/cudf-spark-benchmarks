
WITH  customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM
        customer c
    JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_sales, 0) AS total_web_sales,
        COALESCE(ss.total_sales, 0) AS total_catalog_sales
    FROM
        customer_sales cs
    FULL OUTER JOIN customer_sales ss ON cs.c_customer_sk = ss.c_customer_sk
),
ranked_sales AS (
    SELECT
        css.c_customer_sk,
        css.c_first_name,
        css.c_last_name,
        css.total_web_sales,
        css.total_catalog_sales,
        ROW_NUMBER() OVER (ORDER BY (css.total_web_sales + css.total_catalog_sales) DESC) AS sales_rank
    FROM
        sales_summary css
)
SELECT
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.sales_rank,
    CASE
        WHEN r.sales_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM
    ranked_sales r
WHERE
    r.total_web_sales + r.total_catalog_sales > 1000
ORDER BY
    customer_category, r.sales_rank;

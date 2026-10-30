
WITH  DiscountedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_month_seq = 2
            LIMIT 1
        )
    GROUP BY
        ws_item_sk
    UNION ALL
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid_inc_tax) AS total_sales
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk >= (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_month_seq = 2
            LIMIT 1
        )
    GROUP BY
        cs_item_sk
),
SalesWithPromo AS (
    SELECT
        ds.ws_item_sk,
        ds.total_quantity,
        ds.total_sales,
        COALESCE(p.p_discount_active, 'N') AS discount_active
    FROM
        DiscountedSales ds
    LEFT JOIN promotion p
        ON (ds.ws_item_sk = p.p_item_sk AND p.p_start_date_sk <= 20230228 AND p.p_end_date_sk >= 20230201)
),
RankedSales AS (
    SELECT
        swp.ws_item_sk,
        swp.total_quantity,
        swp.total_sales,
        swp.discount_active,
        ROW_NUMBER() OVER (PARTITION BY swp.discount_active ORDER BY swp.total_sales DESC) AS sales_rank
    FROM
        SalesWithPromo swp
)
SELECT
    i.i_item_id,
    COALESCE(SUM(r.total_sales), 0) AS total_sales,
    COALESCE(SUM(r.total_quantity), 0) AS total_quantity,
    r.discount_active
FROM
    item i
LEFT JOIN RankedSales r ON i.i_item_sk = r.ws_item_sk
WHERE
    r.sales_rank <= 10 OR r.sales_rank IS NULL
GROUP BY
    i.i_item_id, r.discount_active
HAVING
    (COUNT(CASE WHEN r.discount_active = 'Y' THEN 1 END) > 0) OR r.discount_active IS NULL
ORDER BY
    total_sales DESC;

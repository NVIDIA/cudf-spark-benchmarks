WITH CustomerReturnData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count
    FROM
        customer c
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CategorySales AS (
    SELECT
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_category
),
RecentWebPageVisits AS (
    SELECT
        wp.wp_web_page_id,
        COUNT(wp.wp_customer_sk) AS visit_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(wp.wp_customer_sk) DESC) AS rn
    FROM
        web_page wp
    WHERE
        wp.wp_access_date_sk >= (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_date = cast('2002-10-01' as date) - INTERVAL '30 days'
        )
    GROUP BY
        wp.wp_web_page_id
)
SELECT
    cr.c_first_name,
    cr.c_last_name,
    cr.total_return_quantity,
    cr.total_return_amt_inc_tax,
    cs.i_category,
    cs.total_sales,
    rwp.rn
FROM
    CustomerReturnData cr
JOIN
    CategorySales cs ON cs.total_sales > (
        SELECT AVG(total_sales) FROM CategorySales
    )
LEFT JOIN
    RecentWebPageVisits rwp ON rwp.visit_count > 0
WHERE
    cr.total_return_quantity IS NOT NULL
ORDER BY
    cr.total_return_amt_inc_tax DESC,
    cs.total_sales DESC;
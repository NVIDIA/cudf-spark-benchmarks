
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY
        ws.ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.order_count,
        ia.i_item_desc,
        ia.i_brand,
        ia.i_category,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS item_rank
    FROM
        SalesData sd
    JOIN
        item ia ON sd.ws_item_sk = ia.i_item_sk
    WHERE
        sd.sales_rank <= 10
),
CustomerFeedback AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT c.c_customer_sk) AS feedback_count,
        AVG(r.r_reason_sk) AS avg_return_reason
    FROM
        customer c
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN
        reason r ON r.r_reason_sk = sr.sr_reason_sk
    WHERE
        c.c_birth_year < 1980
    GROUP BY
        c.c_customer_id
)
SELECT
    ts.item_rank,
    ts.i_item_desc,
    ts.i_brand,
    ts.i_category,
    ts.total_sales,
    cf.feedback_count,
    cf.avg_return_reason
FROM
    TopSales ts
LEFT JOIN
    CustomerFeedback cf ON ts.i_brand = cf.c_customer_id
WHERE
    (cf.feedback_count > 5 OR cf.feedback_count IS NULL)
ORDER BY
    total_sales DESC;

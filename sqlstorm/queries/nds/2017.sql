WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000)
    GROUP BY
        ws_item_sk
),
CustomerSatisfaction AS (
    SELECT
        sr_item_sk,
        AVG(sr_return_quantity) AS avg_return_rate
    FROM
        store_returns
    GROUP BY
        sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    sd.total_quantity,
    sd.total_sales,
    COALESCE(cs.avg_return_rate, 0) AS avg_return_rate,
    CASE 
        WHEN sd.total_sales > 5000 THEN 'High Performer'
        WHEN sd.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM
    item i
LEFT JOIN
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN
    CustomerSatisfaction cs ON i.i_item_sk = cs.sr_item_sk
WHERE
    i.i_rec_start_date <= cast('2002-10-01' as date)
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    AND i.i_current_price IS NOT NULL
ORDER BY
    sd.total_sales DESC,
    avg_return_rate ASC;
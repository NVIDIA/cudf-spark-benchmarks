
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM
        sales_summary ss
    WHERE
        ss.rank = 1
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT OUTER JOIN
    top_items ti ON c.c_customer_sk = ti.ws_item_sk
WHERE
    c.c_first_name IS NOT NULL
    AND ca.ca_state IN ('CA', 'NY')
    AND ti.sales_rank <= 10
    AND ti.total_sales > (SELECT AVG(total_sales) FROM top_items)
ORDER BY
    ti.total_sales DESC
LIMIT 100;

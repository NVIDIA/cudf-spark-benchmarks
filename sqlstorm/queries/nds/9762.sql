
WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.total_orders) AS total_orders,
        AVG(sd.avg_sales_price) AS avg_sales_price
    FROM
        sales_data sd
    GROUP BY
        sd.ws_item_sk
    ORDER BY
        total_sales DESC
    LIMIT 10
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ti.total_sales,
    ti.total_orders,
    ti.avg_sales_price,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
FROM
    top_items ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_state = 'CA'
ORDER BY
    ti.total_sales DESC;

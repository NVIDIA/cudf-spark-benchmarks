WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2454000 AND 2454600 
    GROUP BY
        ws.ws_order_number, ws.ws_item_sk
),
summary AS (
    SELECT
        sd.ws_item_sk,
        COUNT(sd.ws_order_number) AS total_orders,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.total_discount) AS total_discount,
        SUM(sd.total_tax) AS total_tax
    FROM
        sales_data sd
    GROUP BY
        sd.ws_item_sk
)
SELECT
    i.i_item_id,
    s.total_orders,
    s.total_quantity,
    s.total_sales,
    s.total_discount,
    s.total_tax
FROM
    summary s
JOIN
    item i ON s.ws_item_sk = i.i_item_sk
ORDER BY
    s.total_sales DESC
LIMIT 10;
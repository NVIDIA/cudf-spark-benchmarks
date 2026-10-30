
WITH sales_data AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk
),
top_items AS (
    SELECT
        item.i_item_sk,
        item.i_item_id,
        SUM(sales.total_quantity) AS total_quantity_sold,
        SUM(sales.total_sales) AS total_sales_made
    FROM
        sales_data sales
    JOIN
        item item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY
        item.i_item_sk, item.i_item_id
    ORDER BY
        total_sales_made DESC
    LIMIT 10
)
SELECT
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_sales_made
FROM
    top_items ti
JOIN
    web_sales ws ON ti.i_item_sk = ws.ws_item_sk
JOIN
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_state = 'CA'
    AND ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) 
                                   AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
ORDER BY
    ti.total_sales_made DESC;

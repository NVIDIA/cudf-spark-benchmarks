
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity_sold,
        r.total_sales,
        r.total_discount,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM RankedSales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    WHERE r.rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_sales,
    ti.total_discount,
    ti.i_current_price,
    ti.i_brand,
    ca.ca_city,
    ca.ca_state
FROM TopItems ti
JOIN customer c ON ti.ws_item_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_state IN ('CA', 'TX', 'NY')
ORDER BY ti.total_sales DESC;

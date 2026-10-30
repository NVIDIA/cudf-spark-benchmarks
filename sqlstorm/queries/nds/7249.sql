
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459117 AND 2459124
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_brand
    FROM item i
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        id.i_item_id,
        id.i_product_name,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
    JOIN ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    ws.ws_sold_date_sk,
    ti.i_item_id,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_sales,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status
FROM TopItems ti
JOIN web_sales ws ON ti.ws_item_sk = ws.ws_item_sk 
AND ws.ws_sold_date_sk = ws.ws_sold_date_sk
JOIN CustomerDetails c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ti.sales_rank <= 10
ORDER BY ws.ws_sold_date_sk, ti.total_sales DESC;

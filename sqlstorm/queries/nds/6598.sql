
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
), store_sales_data AS (
    SELECT 
        ss.ss_sold_date_sk, 
        ss.ss_item_sk, 
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
), combined_sales AS (
    SELECT 
        sd.ws_sold_date_sk, 
        sd.ws_item_sk,
        sd.total_quantity AS web_total_quantity,
        sd.total_sales AS web_total_sales,
        sd.total_discount AS web_total_discount,
        COALESCE(ss.total_quantity, 0) AS store_total_quantity,
        COALESCE(ss.total_sales, 0) AS store_total_sales,
        COALESCE(ss.total_discount, 0) AS store_total_discount
    FROM sales_data sd
    LEFT JOIN store_sales_data ss ON sd.ws_sold_date_sk = ss.ss_sold_date_sk AND sd.ws_item_sk = ss.ss_item_sk
)
SELECT 
    cb.ws_sold_date_sk,
    cb.ws_item_sk,
    (cb.web_total_quantity + cb.store_total_quantity) AS total_quantity,
    (cb.web_total_sales + cb.store_total_sales) AS total_sales,
    (cb.web_total_discount + cb.store_total_discount) AS total_discount,
    (cb.web_total_sales - cb.web_total_discount + cb.store_total_sales - cb.store_total_discount) AS net_profit
FROM combined_sales cb
ORDER BY cb.ws_sold_date_sk, cb.ws_item_sk;

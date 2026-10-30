
WITH  sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM
        store_sales
    GROUP BY
        ss_store_sk
), 
item_details AS (
    SELECT 
        i_item_sk,
        COUNT(ws_item_sk) AS sold_times,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_sales_price) AS max_sales_price
    FROM 
        web_sales
    LEFT JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        i_item_sk
), 
customer_info AS (
    SELECT 
        c_customer_sk,
        cd_marital_status,
        cd_gender,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer 
    JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, cd_marital_status, cd_gender
)
SELECT 
    ca.ca_city,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_sales, 0) AS total_sales,
    ci.total_orders,
    ci.total_spent,
    ii.sold_times,
    ii.avg_sales_price,
    ii.max_sales_price
FROM 
    customer_address ca
LEFT JOIN sales_summary ss ON ca.ca_address_sk = ss.ss_store_sk
LEFT JOIN customer_info ci ON ci.c_customer_sk = ss.ss_store_sk
LEFT JOIN item_details ii ON ss.ss_store_sk = ii.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 100;

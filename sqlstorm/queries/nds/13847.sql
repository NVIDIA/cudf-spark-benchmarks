
WITH sales_data AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_item_sk) AS total_items_sold
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        ss_store_sk
),
customer_data AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        customer
    JOIN 
        web_sales ON c_customer_sk = ws_bill_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender
)
SELECT 
    s.total_sales,
    s.total_items_sold,
    c.orders_count,
    c.cd_gender
FROM 
    sales_data s
JOIN 
    customer_data c ON s.ss_store_sk = c.c_customer_sk
ORDER BY 
    s.total_sales DESC;

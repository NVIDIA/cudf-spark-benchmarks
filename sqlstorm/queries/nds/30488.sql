
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        sales_data
    WHERE 
        sales_rank <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS customer_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
sales_summary AS (
    SELECT 
        ts.ws_item_sk, 
        ts.total_quantity, 
        ts.total_sales,
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name,
        COALESCE(cs.customer_sales, 0) AS customer_sales
    FROM 
        top_sales ts
    LEFT JOIN 
        customer_sales cs ON ts.ws_item_sk = cs.c_customer_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_quantity,
    ss.total_sales,
    ss.customer_sales,
    (CASE 
        WHEN ss.customer_sales > 0 THEN 'Yes' 
        ELSE 'No' 
    END) AS made_a_purchase,
    CONCAT(ss.c_first_name, ' ', ss.c_last_name) AS customer_name,
    ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS row_num
FROM 
    sales_summary ss
WHERE 
    ss.total_sales > 1000
ORDER BY 
    ss.total_sales DESC;

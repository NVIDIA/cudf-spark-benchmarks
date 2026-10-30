
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        COUNT(*) OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS sales_count,
        SUM(ws.ws_sales_price) OVER(PARTITION BY ws.ws_item_sk) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458090 AND 2458097
),
top_sales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.sales_count,
        r.total_sales,
        r.price_rank,
        r.w_warehouse_name
    FROM 
        ranked_sales r
    WHERE 
        r.price_rank <= 5
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cd.cd_gender, 'Unknown') AS customer_gender,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
    t.total_sales,
    CASE 
        WHEN t.total_sales > 1000 THEN 'High Value'
        WHEN t.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
INNER JOIN 
    top_sales t ON c.c_customer_sk = t.ws_order_number
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
ORDER BY 
    t.total_sales DESC
LIMIT 10;

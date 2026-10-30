
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(ws.total_quantity, 0) AS total_quantity,
        COALESCE(ws.total_sales, 0) AS total_sales,
        CASE 
            WHEN ws.total_quantity IS NULL THEN 'No Sales'
            ELSE 'Sold'
        END AS sale_status
    FROM 
        item i
    LEFT JOIN sales_data ws ON i.i_item_sk = ws.ws_item_sk
), demographic_info AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
), date_info AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date_sk, d.d_year
)
SELECT 
    item.i_item_desc,
    item.total_quantity,
    item.total_sales,
    item.sale_status,
    dem.gender,
    dem.customer_count,
    date.d_year,
    date.order_count
FROM 
    item_info item
JOIN demographic_info dem ON item.total_sales > 0 AND dem.customer_count > 10
LEFT JOIN date_info date ON item.total_sales BETWEEN 1000 AND 10000
WHERE 
    item.total_quantity IS NOT NULL
    AND (item.total_sales IS NULL OR item.total_sales > 500)
ORDER BY 
    item.total_sales DESC, dem.customer_count DESC
LIMIT 10 OFFSET 5;

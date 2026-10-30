
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk,
        ws_item_sk
), 
high_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(sales.total_sales) AS aggregated_sales
    FROM 
        sales_data sales
    JOIN 
        item item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
    HAVING 
        SUM(sales.total_sales) > 1000
), 
customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 500
)
SELECT 
    hs.i_item_id,
    hs.i_item_desc,
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    COALESCE(cs.total_spent - hs.aggregated_sales, 0) AS remaining_budget
FROM 
    high_sales hs
JOIN 
    customer_sales cs ON hs.aggregated_sales < cs.total_spent
WHERE 
    hs.aggregated_sales IS NOT NULL
ORDER BY 
    remaining_budget DESC
LIMIT 10;


WITH  sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
), 
sales_summary AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(cte.ws_quantity) AS total_quantity,
        SUM(cte.ws_ext_sales_price) AS total_sales,
        COUNT(cte.ws_item_sk) AS sales_count
    FROM 
        sales_cte cte
    JOIN 
        item ON item.i_item_sk = cte.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_sales, 0) AS total_sales,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Roller'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Budget Buyer'
    END AS buyer_category
FROM 
    customer cust
LEFT JOIN 
    sales_summary ss ON ss.total_quantity > 0
WHERE 
    EXISTS (
        SELECT 1 
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = cust.c_current_cdemo_sk 
        AND cd.cd_gender = 'F'
    )
ORDER BY 
    total_sales DESC
LIMIT 10;

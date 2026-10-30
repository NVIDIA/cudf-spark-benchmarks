
WITH  sales_analysis AS (
    SELECT
        ws_order_number,
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY 
        ws_order_number, ws_sold_date_sk, ws_item_sk
),
sales_summary AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(ws.total_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(ws.total_sales), 0) AS total_sales_amount
    FROM 
        item
    LEFT JOIN 
        sales_analysis ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
top_sales AS (
    SELECT 
        i_item_id,
        i_item_desc,
        total_quantity_sold,
        total_sales_amount,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity_sold,
    ts.total_sales_amount,
    CASE 
        WHEN ts.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Not Top 10'
    END AS sales_category,
    substr(item.i_item_desc, 1, 30) || '...' AS short_description,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) AS total_customers,
    (SELECT COUNT(DISTINCT wr_returning_customer_sk) 
     FROM web_returns 
     WHERE wr_item_sk = item.i_item_sk) AS total_returns
FROM 
    top_sales ts
JOIN 
    item ON ts.i_item_id = item.i_item_id
WHERE 
    ts.total_sales_amount > (SELECT AVG(total_sales_amount) FROM sales_summary)
ORDER BY 
    ts.total_sales_amount DESC;

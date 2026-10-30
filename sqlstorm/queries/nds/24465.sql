
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        CASE 
            WHEN total_sales = 0 THEN 'Zero Sales'
            WHEN total_sales BETWEEN 1 AND 10 THEN 'Low Sales'
            WHEN total_sales BETWEEN 11 AND 100 THEN 'Moderate Sales'
            ELSE 'High Sales' 
        END AS sales_category
    FROM 
        SalesCTE
    WHERE 
        sales_rank <= 100
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(a.total_sales, 0) AS total_sales,
        COALESCE(a.order_count, 0) AS order_count,
        a.sales_category
    FROM 
        item i
    LEFT JOIN 
        AggregateSales a ON i.i_item_sk = a.ws_item_sk
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    id.total_sales,
    id.order_count,
    id.sales_category,
    CASE 
        WHEN id.total_sales IS NULL THEN 'No sales data'
        ELSE 
            CONCAT('Product ', id.i_product_name, ' has ', id.total_sales, ' sales in the year 2023.')
    END AS sales_statement,
    COALESCE((SELECT SUM(sr_return_quantity) 
               FROM store_returns sr 
               WHERE sr_item_sk = id.i_item_sk 
               AND sr_returned_date_sk IN 
               (SELECT d_date_sk FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31')), 
              0) AS total_returns 
FROM 
    ItemDetails id
WHERE 
    id.total_sales IS NOT NULL
ORDER BY 
    id.total_sales DESC 
LIMIT 10;

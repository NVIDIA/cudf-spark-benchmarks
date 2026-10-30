WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2000)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
BestSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(sales.total_sales) AS total_quantity_sold,
        SUM(sales.total_revenue) AS total_revenue_generated,
        RANK() OVER (ORDER BY SUM(sales.total_revenue) DESC) AS sales_rank
    FROM 
        SalesCTE AS sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    items.i_item_id,
    items.i_item_desc,
    items.total_quantity_sold,
    items.total_revenue_generated,
    (SELECT COUNT(*) FROM BestSellingItems) AS total_best_selling_items
FROM 
    BestSellingItems AS items
WHERE 
    items.sales_rank <= 10
ORDER BY 
    items.total_revenue_generated DESC;
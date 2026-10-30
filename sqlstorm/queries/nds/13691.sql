
WITH SalesSummary AS (
    SELECT 
        ws_item_sk AS item_id,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.total_orders
FROM 
    item i
JOIN 
    SalesSummary ss ON i.i_item_sk = ss.item_id
ORDER BY 
    ss.total_sales_amount DESC
LIMIT 100;

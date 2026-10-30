
SELECT 
    i.i_item_id,
    i.i_item_desc,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_sales_price) AS total_sales_revenue,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_transactions
FROM 
    item i
JOIN 
    store_sales ss ON i.i_item_sk = ss.ss_item_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    i.i_item_id, i.i_item_desc
ORDER BY 
    total_sales_revenue DESC
LIMIT 
    10;

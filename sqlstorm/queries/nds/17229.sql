
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sum(ss.ss_quantity) as total_sales
FROM 
    item i
JOIN 
    store_sales ss ON i.i_item_sk = ss.ss_item_sk
GROUP BY 
    i.i_item_id, i.i_item_desc
ORDER BY 
    total_sales DESC
LIMIT 10;

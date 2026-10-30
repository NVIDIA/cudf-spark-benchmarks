WITH ranked_sales AS (
    SELECT 
        w.w_warehouse_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_quantity) DESC) AS rank_by_quantity,
        RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_by_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451870  
    GROUP BY 
        w.w_warehouse_id, i.i_item_id
)
SELECT 
    r.w_warehouse_id,
    r.i_item_id,
    r.total_quantity,
    r.total_sales
FROM 
    ranked_sales r
WHERE 
    r.rank_by_quantity <= 5 
    OR r.rank_by_sales <= 5
ORDER BY 
    r.w_warehouse_id, r.total_quantity DESC, r.total_sales DESC;
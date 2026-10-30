
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_paid DESC) AS sale_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS item_recent_sale
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459202 AND 2459205
),
ItemSalesJoin AS (
    SELECT 
        rs.ws_sold_date_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    LEFT JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        web_sales ws ON rs.ws_item_sk = ws.ws_item_sk AND rs.ws_sold_date_sk = ws.ws_sold_date_sk
    WHERE 
        rs.sale_rank <= 10
    GROUP BY 
        rs.ws_sold_date_sk, i.i_item_id, i.i_item_desc
)
SELECT 
    d.d_date, 
    isj.i_item_id, 
    isj.i_item_desc, 
    isj.total_net_paid,
    isj.total_quantity,
    COALESCE(isj.order_count, 0) AS orders,
    CASE 
        WHEN isj.total_net_paid > 500 THEN 'High'
        WHEN isj.total_net_paid BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM
    date_dim d
LEFT JOIN 
    ItemSalesJoin isj ON d.d_date_sk = isj.ws_sold_date_sk
WHERE 
    d.d_date BETWEEN '2023-10-01' AND '2023-10-31'
ORDER BY 
    d.d_date, isj.total_net_paid DESC;

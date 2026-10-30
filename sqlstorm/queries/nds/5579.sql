
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        ss.total_quantity_sold,
        ss.total_net_paid,
        ss.avg_net_paid,
        ss.order_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_quantity_sold DESC) AS rank
    FROM 
        SalesSummary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.total_quantity_sold > 100
)
SELECT 
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_net_paid,
    ti.avg_net_paid,
    ti.order_count
FROM 
    TopItems ti
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_quantity_sold DESC;

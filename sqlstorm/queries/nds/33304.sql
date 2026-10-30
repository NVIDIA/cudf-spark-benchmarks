
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), 
RankedSales AS (
    SELECT 
        w.ws_item_sk,
        w.ws_sold_date_sk,
        w.total_sold,
        w.total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SalesCTE AS w
    WHERE 
        w.rnk = 1
)
SELECT 
    ia.i_item_id,
    ia.i_item_desc,
    COALESCE(rs.total_sold, 0) AS total_sold,
    COALESCE(rs.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN rs.total_revenue IS NULL THEN 'No Sales Data'
        ELSE 'Sales Data Available'
    END AS sales_data_status
FROM 
    item AS ia
LEFT JOIN 
    RankedSales AS rs 
ON 
    ia.i_item_sk = rs.ws_item_sk
WHERE 
    ia.i_current_price > 20  
    AND (ia.i_formulation IS NULL OR ia.i_formulation <> 'None')
    AND EXISTS (
        SELECT 1 
        FROM promotion AS p 
        WHERE p.p_item_sk = ia.i_item_sk 
        AND p.p_start_date_sk <= (SELECT MAX(ws_ship_date_sk) FROM web_sales)
        AND p.p_end_date_sk >= (SELECT MIN(ws_ship_date_sk) FROM web_sales)
    )
ORDER BY 
    total_revenue DESC, 
    ia.i_item_desc;

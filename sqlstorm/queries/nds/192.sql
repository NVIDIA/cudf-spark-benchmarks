
WITH ReturnSummary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
WebSalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_sales,
        COUNT(DISTINCT ws_order_number) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Promotions AS (
    SELECT 
        p_item_sk,
        COUNT(DISTINCT p_promo_sk) AS promo_count
    FROM 
        promotion
    GROUP BY 
        p_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price
    FROM 
        item
)
SELECT 
    id.i_item_sk,
    id.i_product_name,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_value, 0) AS total_return_value,
    COALESCE(ws.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ws.total_net_sales, 0) AS total_net_sales,
    COALESCE(p.promo_count, 0) AS promo_count,
    (COALESCE(ws.total_quantity_sold, 0) - COALESCE(rs.total_returns, 0)) AS net_sales_after_returns,
    CASE 
        WHEN COALESCE(ws.total_quantity_sold, 0) > 0 THEN 
            (COALESCE(ws.total_net_sales, 0) / COALESCE(ws.total_quantity_sold, 0))
        ELSE 0 
    END AS avg_sales_price,
    CASE 
        WHEN COALESCE(ws.total_net_sales, 0) > 0 THEN 
            (COALESCE(rs.total_return_value, 0) / COALESCE(ws.total_net_sales, 0)) * 100
        ELSE 0 
    END AS return_percentage
FROM 
    ItemDetails id
LEFT JOIN 
    ReturnSummary rs ON id.i_item_sk = rs.sr_item_sk
LEFT JOIN 
    WebSalesSummary ws ON id.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    Promotions p ON id.i_item_sk = p.p_item_sk
WHERE 
    COALESCE(ws.total_quantity_sold, 0) > 100 OR COALESCE(rs.total_returns, 0) > 5
ORDER BY 
    total_return_value DESC, 
    net_sales_after_returns DESC;

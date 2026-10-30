
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as rank_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) as row_qty
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
FilteredInventory AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        CASE 
            WHEN inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand <= 0 THEN 'Out of Stock'
            ELSE 'In Stock' 
        END as stock_status
    FROM 
        inventory inv
),
CustomerReturnStats AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(CASE WHEN sr.sr_reason_sk IS NULL THEN 1 END) AS returns_without_reason
    FROM 
        store_returns sr
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        sr.sr_item_sk
),
WebSalesDetail AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    i.i_item_id,
    COALESCE(s.total_returns, 0) AS total_returns,
    COALESCE(s.total_return_qty, 0) AS total_return_qty,
    COALESCE(s.avg_return_amt, 0.00) AS avg_return_amt,
    COALESCE(stock.inv_quantity_on_hand, 0) AS quantity_on_hand,
    COALESCE(stock.stock_status, 'Unknown') AS stock_status,
    CASE 
        WHEN r.rank_price = 1 THEN 'Top Seller' 
        WHEN r.row_qty = 1 THEN 'Best Quantity Seller'
        ELSE 'Regular Seller'
    END AS sales_category,
    COALESCE(w.total_sales, 0) AS total_sales,
    COALESCE(w.total_net_profit, 0) AS total_net_profit
FROM 
    item i
LEFT JOIN 
    CustomerReturnStats s ON i.i_item_sk = s.sr_item_sk
LEFT JOIN 
    FilteredInventory stock ON i.i_item_sk = stock.inv_item_sk
LEFT JOIN 
    RankedSales r ON i.i_item_sk = r.ws_item_sk
LEFT JOIN 
    WebSalesDetail w ON i.i_item_sk = w.ws_item_sk
WHERE 
    (stock.inv_quantity_on_hand IS NOT NULL OR s.total_returns IS NOT NULL OR w.unique_orders > 0)
    AND (i.i_current_price BETWEEN 5.00 AND 100.00 OR i.i_item_id LIKE '%A%')
ORDER BY 
    w.total_net_profit DESC, 
    s.total_return_qty ASC
LIMIT 50;

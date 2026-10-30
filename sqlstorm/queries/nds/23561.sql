
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
Returns_CTE AS (
    SELECT 
        wr_item_sk AS ws_item_sk, 
        COUNT(wr_return_quantity) AS total_returns 
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
), 
Final_Sales AS (
    SELECT 
        sc.ws_item_sk,
        sc.total_sales,
        COALESCE(rc.total_returns, 0) AS total_returns,
        (sc.total_sales - COALESCE(rc.total_returns * 10, 0)) AS net_profit, 
        CASE 
            WHEN sc.order_count = 0 THEN 0 
            ELSE (sc.total_sales / NULLIF(sc.order_count, 0)) 
        END AS average_order_value,
        CASE 
            WHEN rc.total_returns IS NULL OR rc.total_returns = 0 THEN 'No Returns'
            ELSE 'With Returns'
        END AS return_status
    FROM 
        Sales_CTE sc
    LEFT JOIN 
        Returns_CTE rc ON sc.ws_item_sk = rc.ws_item_sk
    WHERE 
        sc.sales_rank <= 10
)

SELECT 
    item.i_item_id,
    item.i_item_desc,
    fs.total_sales,
    fs.total_returns,
    fs.net_profit,
    fs.average_order_value,
    fs.return_status,
    w.w_warehouse_id,
    CASE 
        WHEN fs.net_profit < 0 THEN 'Loss'
        WHEN fs.net_profit = 0 THEN 'Break Even'
        ELSE 'Profit' 
    END AS profit_status
FROM 
    Final_Sales fs 
JOIN 
    item ON fs.ws_item_sk = item.i_item_sk
JOIN 
    inventory i ON i.inv_item_sk = item.i_item_sk
JOIN 
    warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    i.inv_quantity_on_hand > 0
ORDER BY 
    fs.total_sales DESC;

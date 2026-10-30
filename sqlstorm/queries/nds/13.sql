
WITH ItemSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
), 
StoreSales AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_quantity) AS total_quantity, 
        SUM(ss_net_paid) AS total_sales
    FROM 
        store_sales 
    GROUP BY 
        ss_item_sk
), 
StoreReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
), 
WebReturns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
), 
CombinedSales AS (
    SELECT 
        i.i_item_sk,
        COALESCE(ws.total_quantity, 0) AS online_sales_quantity,
        COALESCE(ws.total_sales, 0) AS online_sales_value,
        COALESCE(ss.total_quantity, 0) AS store_sales_quantity,
        COALESCE(ss.total_sales, 0) AS store_sales_value,
        COALESCE(sr.total_returns, 0) AS store_returns,
        COALESCE(wr.total_returns, 0) AS web_returns
    FROM 
        item i
    LEFT JOIN 
        ItemSales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        StoreSales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        StoreReturns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN 
        WebReturns wr ON i.i_item_sk = wr.wr_item_sk
)
SELECT 
    *,
    online_sales_value + store_sales_value - (store_returns + web_returns) AS net_sales,
    RANK() OVER (ORDER BY online_sales_value + store_sales_value DESC) AS sales_rank,
    CASE 
        WHEN online_sales_value > store_sales_value THEN 'Online'
        WHEN store_sales_value > online_sales_value THEN 'In-Store'
        ELSE 'Equal'
    END AS sales_preference
FROM 
    CombinedSales
WHERE 
    (online_sales_quantity + store_sales_quantity) > 100 
    AND (online_sales_value + store_sales_value - (store_returns + web_returns)) > 0
ORDER BY 
    sales_rank;

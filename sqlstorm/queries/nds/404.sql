
WITH CTE_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), 
CTE_Returns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
CTE_Item AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(cs_total.total_sales, 0) AS total_sales_count,
        COALESCE(cr_total.total_returns, 0) AS total_returns_count
    FROM 
        item i
    LEFT JOIN (
        SELECT 
            cs.cs_item_sk,
            SUM(cs.cs_quantity) AS total_sales
        FROM 
            catalog_sales cs
        GROUP BY 
            cs.cs_item_sk
    ) cs_total ON i.i_item_sk = cs_total.cs_item_sk
    LEFT JOIN (
        SELECT 
            sr.sr_item_sk,
            SUM(sr.sr_return_quantity) AS total_returns
        FROM 
            store_returns sr
        GROUP BY 
            sr.sr_item_sk
    ) cr_total ON i.i_item_sk = cr_total.sr_item_sk
),
Final_Report AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        item.i_current_price,
        sales.total_quantity AS web_sales_quantity,
        sales.total_net_profit AS web_net_profit,
        returns.total_returns AS web_return_count,
        (COALESCE(sales.total_net_profit, 0) - COALESCE(returns.total_return_amount, 0)) AS net_profit_after_returns
    FROM 
        CTE_Item item
    LEFT JOIN CTE_Sales sales ON item.i_item_sk = sales.ws_item_sk
    LEFT JOIN CTE_Returns returns ON item.i_item_sk = returns.wr_item_sk
)
SELECT 
    fr.i_item_sk,
    fr.i_item_desc,
    fr.i_current_price,
    COALESCE(fr.web_sales_quantity, 0) AS total_web_sales_quantity,
    COALESCE(fr.web_net_profit, 0) AS total_web_net_profit,
    COALESCE(fr.web_return_count, 0) AS total_web_return_count,
    CASE 
        WHEN fr.web_return_count > 0 THEN 'High Return Rate'
        ELSE 'Normal'
    END AS return_rate_category,
    fr.net_profit_after_returns
FROM 
    Final_Report fr
WHERE 
    (fr.net_profit_after_returns < 0 OR fr.web_return_count > 10)
ORDER BY 
    fr.net_profit_after_returns ASC, fr.web_sales_quantity DESC;

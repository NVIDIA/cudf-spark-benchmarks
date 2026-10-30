
WITH  CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 0
), ItemSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT MIN(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_item_sk
), MarketingAnalysis AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(s.total_orders, 0) AS total_orders,
        COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        (COALESCE(s.total_net_profit, 0) - COALESCE(cr.total_return_amount, 0)) AS adjusted_net_profit
    FROM 
        item i
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
    LEFT JOIN 
        ItemSales s ON i.i_item_sk = s.ws_item_sk
), FinalReport AS (
    SELECT 
        ma.i_item_id,
        ma.total_return_quantity,
        ma.total_return_amount,
        ma.total_orders,
        ma.total_quantity_sold,
        ma.total_net_profit,
        ma.adjusted_net_profit,
        CASE 
            WHEN ma.adjusted_net_profit < 0 THEN 'Loss'
            WHEN ma.adjusted_net_profit = 0 THEN 'Break-even'
            ELSE 'Profit' 
        END AS profitability_status
    FROM 
        MarketingAnalysis ma
    WHERE 
        ma.adjusted_net_profit <> 0
)
SELECT 
    f.i_item_id,
    f.total_return_quantity,
    f.total_return_amount,
    f.total_orders,
    f.total_quantity_sold,
    f.total_net_profit,
    ROUND(f.adjusted_net_profit, 2) AS adjusted_net_profit,
    f.profitability_status
FROM 
    FinalReport f
ORDER BY 
    f.adjusted_net_profit DESC
LIMIT 100;

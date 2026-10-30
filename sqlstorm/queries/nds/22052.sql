
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank_order
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_paid_inc_tax) > 0
), HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_item_sk
    HAVING 
        AVG(sr_return_amt_inc_tax) IS NOT NULL
), DetailedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        CASE 
            WHEN ws.ws_net_profit IS NULL THEN 'No Profit'
            ELSE 'Profit'
        END AS profit_status,
        COALESCE(r.total_quantity, 0) AS total_sales,
        r.total_revenue,
        COALESCE(hr.total_returns, 0) AS total_returns,
        hr.avg_return_amt
    FROM 
        web_sales ws
    LEFT JOIN 
        RankedSales r ON ws.ws_item_sk = r.ws_item_sk AND r.rank_order = 1
    LEFT JOIN 
        HighValueReturns hr ON ws.ws_item_sk = hr.sr_item_sk
)
SELECT 
    ds.ws_item_sk,
    ds.ws_order_number,
    ds.total_sales,
    ds.total_revenue,
    ds.total_returns,
    ds.avg_return_amt,
    CASE 
        WHEN ds.total_sales < 10 AND ds.total_returns > 5 THEN 'High Return Rate'
        WHEN ds.total_sales > 50 AND ds.total_returns < 1 THEN 'Low Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_category
FROM 
    DetailedSales ds
WHERE 
    ds.profit_status = 'Profit' 
    AND (ds.total_revenue > 1000 OR ds.avg_return_amt IS NULL)
ORDER BY 
    ds.total_revenue DESC, 
    ds.total_returns ASC
LIMIT 50;

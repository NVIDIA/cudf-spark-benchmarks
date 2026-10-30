
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt,
        SUM(sr_return_tax) AS total_returned_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ReturnsWithItem AS (
    SELECT 
        rr.sr_item_sk,
        rr.total_returns,
        rr.total_returned_quantity,
        rr.total_returned_amt,
        rr.total_returned_tax,
        i.i_item_desc,
        i.i_current_price,
        i.i_category,
        i.i_size,
        (CASE 
            WHEN rr.total_returned_amt > 1000 THEN 'High Value Return'
            WHEN rr.total_returned_amt BETWEEN 500 AND 1000 THEN 'Medium Value Return'
            ELSE 'Low Value Return'
        END) AS return_value_category
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.rn = 1
),
AllSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
SalesSummary AS (
    SELECT 
        ais.ws_item_sk,
        ais.total_net_profit,
        ais.total_sales_count,
        COALESCE(rr.total_returns, 0) AS total_returns,
        (ais.total_net_profit / NULLIF(ais.total_sales_count, 0)) AS avg_net_profit_per_sale,
        (ais.total_net_profit / NULLIF(rr.total_returns, 0)) AS avg_net_profit_per_return
    FROM 
        AllSales ais
    LEFT JOIN 
        ReturnsWithItem rr ON ais.ws_item_sk = rr.sr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_net_profit,
    s.total_sales_count,
    s.avg_net_profit_per_sale,
    s.avg_net_profit_per_return,
    r.return_value_category
FROM 
    SalesSummary s
LEFT JOIN 
    ReturnsWithItem r ON s.total_returns = r.total_returns
WHERE 
    s.total_sales_count > 10
    AND (s.avg_net_profit_per_sale IS NOT NULL OR s.avg_net_profit_per_return IS NOT NULL)
ORDER BY 
    s.total_net_profit DESC,
    s.total_sales_count ASC
LIMIT 50;


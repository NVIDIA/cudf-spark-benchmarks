
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as sales_rank,
        ws.ws_net_profit,
        CASE 
            WHEN ws.ws_quantity = 0 THEN NULL 
            ELSE (ws.ws_net_profit / NULLIF(ws.ws_quantity, 0)) 
        END AS profit_per_unit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
), HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_category,
        SUM(RS.ws_net_profit) AS total_profit
    FROM 
        RankedSales RS
    JOIN 
        item item ON RS.ws_item_sk = item.i_item_sk
    WHERE 
        RS.sales_rank <= 10
    GROUP BY 
        item.i_item_id, item.i_category
), CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), ReturnAnalysis AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(cr.total_return_amt, 0) > 100 THEN 'High'
            WHEN COALESCE(cr.total_return_amt, 0) BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
), FinalReport AS (
    SELECT 
        r.c_customer_id,
        h.total_profit,
        r.return_category,
        h.i_category,
        CASE 
            WHEN h.total_profit IS NULL THEN 'No Sales'
            ELSE 'Has Sales'
        END AS sales_status,
        r.return_count
    FROM 
        HighProfitItems h
    LEFT JOIN 
        ReturnAnalysis r ON h.i_category = r.return_category
)
SELECT 
    f.c_customer_id,
    f.total_profit,
    f.return_category,
    f.sales_status,
    f.return_count,
    CASE 
        WHEN f.return_count > 0 AND f.total_profit IS NOT NULL THEN 'High Risk'
        ELSE 'Normal'
    END AS risk_status
FROM 
    FinalReport f
WHERE 
    f.total_profit IS NOT NULL
ORDER BY 
    f.total_profit DESC, f.return_count;


WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
), 
CustomerSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_sales_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IS NOT NULL
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ReturnRatio AS (
    SELECT 
        cr.sr_item_sk,
        cr.total_returns,
        COALESCE(cs.total_sold, 0) AS total_sold,
        CASE 
            WHEN COALESCE(cs.total_sold, 0) = 0 THEN 0
            ELSE CAST(cr.total_returns AS DECIMAL) / cs.total_sold 
        END AS return_ratio
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        CustomerSales cs ON cr.sr_item_sk = cs.ws_item_sk
),
RankedReturnRatio AS (
    SELECT 
        rr.sr_item_sk,
        rr.total_returns,
        rr.total_sold,
        rr.return_ratio,
        RANK() OVER (ORDER BY rr.return_ratio DESC) AS rank
    FROM 
        ReturnRatio rr
)
SELECT 
    ir.i_item_id,
    ir.i_item_desc,
    rr.total_returns,
    rr.total_sold,
    rr.return_ratio,
    CASE 
        WHEN rr.return_ratio > 1.0 THEN 'High Return'
        WHEN rr.return_ratio BETWEEN 0.5 AND 1.0 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    RankedReturnRatio rr
JOIN 
    item ir ON rr.sr_item_sk = ir.i_item_sk
WHERE 
    rr.rank <= 10
ORDER BY 
    rr.return_ratio DESC;

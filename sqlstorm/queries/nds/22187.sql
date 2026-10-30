WITH RecentReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned,
        AVG(sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS unique_tickets
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        sr_item_sk
),
TopReturnedItems AS (
    SELECT 
        rr.sr_item_sk,
        rr.total_returned,
        rr.avg_return_amt,
        ROW_NUMBER() OVER (ORDER BY rr.total_returned DESC) AS rn
    FROM 
        RecentReturns rr
    WHERE 
        rr.total_returned > 5
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
FinalReport AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returned, 0) AS total_returned,
        COALESCE(r.avg_return_amt, 0) AS avg_return_amt,
        COALESCE(s.avg_profit, 0) AS avg_profit,
        CASE 
            WHEN COALESCE(s.total_sales, 0) - COALESCE(r.total_returned, 0) < 0 
            THEN 'Loss'
            ELSE 'Profit'
        END AS profitability_status
    FROM 
        item ti
    LEFT JOIN 
        SalesData s ON ti.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        RecentReturns r ON ti.i_item_sk = r.sr_item_sk
    WHERE 
        ti.i_rec_start_date <= cast('2002-10-01' as date) AND (ti.i_rec_end_date IS NULL OR ti.i_rec_end_date > cast('2002-10-01' as date))
)
SELECT 
    *,
    CASE 
        WHEN profitability_status = 'Loss' AND total_returned > 10 THEN 'High Attention Needed'
        WHEN profitability_status = 'Profit' AND total_sales > 1000 THEN 'High Performer'
        ELSE 'Standard'
    END AS item_category
FROM 
    FinalReport
WHERE 
    avg_profit IS NOT NULL AND total_sales > 0
ORDER BY 
    total_returned DESC, avg_profit DESC
LIMIT 10;
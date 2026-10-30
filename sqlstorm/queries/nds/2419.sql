WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND ws.ws_sold_date_sk BETWEEN 2458008 AND 2458768  
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_quantity_sold, 
        ss.total_sales_amount
    FROM 
        SalesSummary ss
    WHERE 
        ss.rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 2458008 AND 2458768  
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        tsi.ws_item_sk, 
        tsi.total_quantity_sold, 
        tsi.total_sales_amount,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN cr.total_return_amount IS NULL OR cr.total_return_amount = 0 THEN 'No Returns'
            WHEN (cr.total_return_amount / tsi.total_sales_amount) > 0.1 THEN 'High Return Rate'
            ELSE 'Normal Return Rate'
        END AS return_rate_category
    FROM 
        TopSellingItems tsi
    LEFT JOIN 
        CustomerReturns cr ON tsi.ws_item_sk = cr.sr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    fr.total_quantity_sold,
    fr.total_sales_amount,
    fr.return_count,
    fr.total_return_amount,
    fr.return_rate_category
FROM 
    FinalReport fr
JOIN 
    item ON fr.ws_item_sk = item.i_item_sk
ORDER BY 
    fr.total_sales_amount DESC;
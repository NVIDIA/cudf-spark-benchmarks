WITH  DiscountedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451571 AND 2451575  
    GROUP BY 
        ws_item_sk
),
CustomerReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemPerformance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        ds.total_sales,
        ds.total_orders,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_quantity,
        COALESCE(ds.total_sales * 0.1, 0) AS estimated_profit,  
        CASE 
            WHEN cr.total_returns IS NULL THEN 'No Returns'
            WHEN cr.total_return_quantity > 100 THEN 'High Returns'
            ELSE 'Normal Returns'
        END AS return_status
    FROM 
        DiscountedSales ds
    JOIN 
        item i ON ds.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        CustomerReturnStats cr ON ds.ws_item_sk = cr.sr_item_sk
    WHERE 
        i.i_current_price IS NOT NULL 
        AND i.i_current_price > 20.00  
)
SELECT 
    ip.i_item_id,
    ip.total_sales,
    ip.total_orders,
    ip.total_returns,
    ip.return_status,
    ROW_NUMBER() OVER (ORDER BY ip.total_sales DESC) AS rank
FROM 
    ItemPerformance ip
WHERE 
    ip.estimated_profit > 0
ORDER BY 
    ip.total_sales DESC
LIMIT 10;
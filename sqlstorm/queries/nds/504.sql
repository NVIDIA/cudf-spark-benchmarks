
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as price_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk DESC) as recent_sales
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) as total_returns,
        SUM(sr.sr_return_amt_inc_tax) as total_return_value
    FROM 
        store_returns sr 
    GROUP BY 
        sr.sr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(cr.total_returns, 0) as total_returns,
        COALESCE(cr.total_return_value, 0) as total_return_value
    FROM 
        item i
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
)
SELECT 
    itd.i_item_sk,
    itd.i_item_desc,
    itd.i_current_price,
    r.ws_order_number,
    r.price_rank,
    r.recent_sales,
    CASE 
        WHEN r.price_rank = 1 THEN 'Highest Price'
        ELSE 'Not Highest Price'
    END as price_category,
    itd.total_returns,
    itd.total_return_value,
    CASE 
        WHEN itd.total_return_value > 100 THEN 'High Return Value'
        ELSE 'Low Return Value'
    END as return_value_category
FROM 
    RankedSales r
JOIN 
    ItemDetails itd ON r.ws_item_sk = itd.i_item_sk
WHERE 
    r.price_rank <= 5
ORDER BY 
    r.ws_order_number, 
    r.price_rank;

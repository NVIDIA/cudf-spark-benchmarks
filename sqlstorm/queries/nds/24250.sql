
WITH CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_fee) AS total_return_fee
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
), 
FlaggedItems AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_current_price,
        CASE 
            WHEN i_current_price IS NULL THEN 'MISSING'
            WHEN i_current_price > 1000 THEN 'EXPENSIVE'
            ELSE 'AFFORDABLE' 
        END AS price_category
    FROM 
        item 
    WHERE 
        i_rec_start_date <= '2002-10-01' 
        AND (i_rec_end_date IS NULL OR i_rec_end_date > '2002-10-01')
), 
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 100
    GROUP BY 
        ws_item_sk
), 
CombinedData AS (
    SELECT 
        fi.i_item_sk,
        fi.i_item_id,
        fi.i_item_desc,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        fi.price_category,
        CASE 
            WHEN COALESCE(cr.total_return_quantity, 0) = 0 AND COALESCE(sd.total_sales_quantity, 0) = 0 THEN 'NO SALES OR RETURNS'
            WHEN COALESCE(cr.total_return_quantity, 0) > COALESCE(sd.total_sales_quantity, 0) THEN 'HIGH RETURN RATE'
            ELSE 'NORMAL'
        END AS return_status
    FROM 
        FlaggedItems fi
    LEFT JOIN 
        CustomerReturns cr ON fi.i_item_sk = cr.sr_item_sk
    LEFT JOIN 
        SalesData sd ON fi.i_item_sk = sd.ws_item_sk
)
SELECT 
    i_item_id,
    i_item_desc,
    total_return_quantity,
    total_sales_quantity,
    price_category,
    return_status,
    ROW_NUMBER() OVER (PARTITION BY price_category ORDER BY total_sales_quantity DESC) AS rank_within_category
FROM 
    CombinedData
WHERE 
    return_status <> 'NO SALES OR RETURNS'
ORDER BY 
    price_category, total_sales_quantity DESC;

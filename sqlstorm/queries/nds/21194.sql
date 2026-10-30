
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_ext_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        AVG(wr_return_amt_inc_tax) AS avg_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(ib_lower_bound, 0) AS lower_income,
        COALESCE(ib_upper_bound, 100000) AS upper_income
    FROM 
        item
    LEFT JOIN 
        income_band ON item.i_item_sk % 10 = income_band.ib_income_band_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    rs.ws_sales_price,
    rs.ws_quantity,
    COALESCE(cr.total_returned, 0) AS total_returns,
    COALESCE(cr.avg_return_amt, 0) AS avg_return_amount,
    CASE 
        WHEN rs.ws_sales_price >= id.i_current_price THEN 'Profitable'
        ELSE 'Loss'
    END AS profitability_status,
    CASE 
        WHEN rs.ws_quantity > 0 THEN 'Sold'
        ELSE 'Not Sold'
    END AS sale_status,
    id.lower_income,
    id.upper_income
FROM 
    ItemDetails id
LEFT JOIN 
    RankedSales rs ON id.i_item_sk = rs.ws_item_sk AND rs.rn = 1
LEFT JOIN 
    CustomerReturns cr ON id.i_item_sk = cr.wr_item_sk
WHERE 
    id.i_item_desc LIKE '%Special%'
    OR (id.upper_income - id.lower_income > 50000 AND cr.total_returned IS NULL)
ORDER BY 
    profitability_status DESC, 
    total_returns DESC,
    sale_status ASC;

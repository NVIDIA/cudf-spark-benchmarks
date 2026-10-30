WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rn,
        COALESCE(sm.sm_type, 'UNKNOWN') AS ship_type
    FROM 
        web_sales ws
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459059 AND 2459065 
),
ReturnsData AS (
    SELECT 
        cr.cr_order_number,
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_order_number, cr.cr_item_sk
),
CombinedData AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_ext_sales_price,
        sd.ws_ext_discount_amt,
        rd.total_returns,
        rd.total_return_amount,
        sd.ship_type
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnsData rd ON sd.ws_order_number = rd.cr_order_number AND sd.ws_item_sk = rd.cr_item_sk
)
SELECT 
    COUNT(*) AS total_records,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(ws_quantity, 0)) AS total_units_sold,
    SUM(COALESCE(total_returns, 0)) AS total_units_returned,
    SUM(COALESCE(total_return_amount, 0)) AS total_revenue_loss,
    MAX(ws_ext_sales_price) AS highest_sale,
    MIN(ws_ext_sales_price) AS lowest_sale
FROM 
    CombinedData
WHERE 
    total_returns IS NOT NULL AND 
    (total_return_amount > 100 OR ship_type = 'EXPRESS') 
HAVING 
    COUNT(ship_type) > 0
ORDER BY 
    total_sales DESC
LIMIT 50 OFFSET 10;

WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
        COALESCE(sr.sr_return_amt, 0) AS return_amt,
        COALESCE(cr.cr_return_quantity, 0) AS catalog_return_quantity,
        COALESCE(cr.cr_return_amount, 0) AS catalog_return_amt,
        wd.d_week_seq,
        wd.d_year
    FROM 
        web_sales ws
    LEFT JOIN 
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number AND ws.ws_item_sk = sr.sr_item_sk
    LEFT JOIN 
        catalog_returns cr ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
),

summary AS (
    SELECT 
        d_year,
        d_week_seq,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(return_quantity) AS total_returns,
        SUM(return_amt) AS total_returned_amt,
        SUM(catalog_return_quantity) AS total_catalog_returns,
        SUM(catalog_return_amt) AS total_catalog_returned_amt
    FROM 
        sales_data
    GROUP BY 
        d_year, d_week_seq
)

SELECT 
    s.d_year,
    s.d_week_seq,
    s.total_orders,
    s.total_sales,
    s.total_returns,
    s.total_returned_amt,
    s.total_catalog_returns,
    s.total_catalog_returned_amt,
    (s.total_sales - s.total_returned_amt - s.total_catalog_returned_amt) AS net_sales,
    CASE 
        WHEN s.total_orders > 0 THEN (s.total_sales / s.total_orders) 
        ELSE 0 
    END AS average_order_value
FROM 
    summary s
ORDER BY 
    s.d_year, s.d_week_seq;

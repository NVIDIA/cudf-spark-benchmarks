
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_quantity,
        cs.cs_sales_price,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(cr.cr_return_amount) AS total_catalog_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
    LEFT JOIN 
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
    LEFT JOIN 
        catalog_returns cr ON ws.ws_item_sk = cr.cr_item_sk AND ws.ws_order_number = cr.cr_order_number
    GROUP BY 
        ws.ws_order_number, ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_sales_price, ws.ws_ext_sales_price, cs.cs_quantity, cs.cs_sales_price, sr.sr_return_quantity, sr.sr_return_amt, sr.sr_net_loss, cr.cr_return_quantity, cr.cr_return_amount, cr.cr_net_loss
),
AggregatedData AS (
    SELECT 
        sd.ws_order_number,
        COUNT(sd.ws_item_sk) AS total_items_sold,
        SUM(sd.ws_quantity) AS total_units_sold,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        SUM(sd.total_sales) AS total_sales_value,
        SUM(sd.total_returns) AS total_returns_value,
        SUM(sd.total_catalog_returns) AS total_catalog_returns_value,
        (SUM(sd.total_sales) - SUM(sd.total_returns) - SUM(sd.total_catalog_returns)) AS net_revenue
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_order_number
)
SELECT 
    ad.ws_order_number,
    ad.total_items_sold, 
    ad.total_units_sold,
    ad.avg_sales_price,
    ad.total_sales_value, 
    ad.total_returns_value, 
    ad.total_catalog_returns_value,
    ad.net_revenue
FROM 
    AggregatedData ad
ORDER BY 
    ad.net_revenue DESC
LIMIT 10;

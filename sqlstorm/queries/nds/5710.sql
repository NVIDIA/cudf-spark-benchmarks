
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
        COALESCE(sr.sr_return_amt, 0) AS return_amount,
        COALESCE(sr.sr_net_loss, 0) AS return_loss,
        COALESCE(cr.cr_return_quantity, 0) AS catalog_return_quantity,
        COALESCE(cr.cr_return_amount, 0) AS catalog_return_amount,
        COALESCE(cr.cr_net_loss, 0) AS catalog_return_loss,
        COALESCE(wr.wr_return_quantity, 0) AS web_return_quantity,
        COALESCE(wr.wr_return_amt, 0) AS web_return_amount,
        COALESCE(wr.wr_net_loss, 0) AS web_return_loss
    FROM
        web_sales ws
    LEFT JOIN
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
    LEFT JOIN
        catalog_returns cr ON ws.ws_item_sk = cr.cr_item_sk AND ws.ws_order_number = cr.cr_order_number
    LEFT JOIN
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
),
AggregatedData AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(sd.ws_quantity) AS total_quantity_sold,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        SUM(sd.return_quantity) AS total_returned_quantity,
        SUM(sd.return_amount) AS total_returned_amount,
        SUM(sd.catalog_return_quantity) AS total_catalog_returned_quantity,
        SUM(sd.catalog_return_amount) AS total_catalog_returned_amount,
        SUM(sd.web_return_quantity) AS total_web_returned_quantity,
        SUM(sd.web_return_amount) AS total_web_returned_amount,
        (SUM(sd.ws_ext_sales_price) - SUM(sd.return_amount) - SUM(sd.catalog_return_amount) - SUM(sd.web_return_amount)) AS net_sales
    FROM
        SalesData sd
    JOIN
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
)
SELECT
    ad.d_year,
    ad.d_month_seq,
    ad.total_quantity_sold,
    ad.total_sales,
    ad.total_returned_quantity,
    ad.total_returned_amount,
    ad.total_catalog_returned_quantity,
    ad.total_catalog_returned_amount,
    ad.total_web_returned_quantity,
    ad.total_web_returned_amount,
    ad.net_sales
FROM
    AggregatedData ad
ORDER BY
    ad.d_year, ad.d_month_seq;


WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
), 
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
), 
HighReturnItems AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_order_number IN (SELECT sr_ticket_number FROM store_returns)
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    COALESCE(pi.total_sold_quantity, 0) AS sold_quantity,
    COALESCE(pi.total_sales_amount, 0) AS total_sales,
    COALESCE(hi.total_return_quantity, 0) AS returned_quantity,
    COALESCE(hi.total_return_amount, 0) AS total_return
FROM 
    item ci
LEFT JOIN 
    PopularItems pi ON ci.i_item_sk = pi.ws_item_sk
LEFT JOIN 
    HighReturnItems hi ON ci.i_item_sk = hi.cr_item_sk
WHERE 
    ci.i_current_price > 10.00
ORDER BY 
    total_sales DESC, 
    returned_quantity DESC
LIMIT 50;

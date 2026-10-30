
WITH  SalesData AS (
    SELECT 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_order_number

    UNION ALL

    SELECT 
        cs_order_number, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_sales_price) AS total_sales 
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs_order_number
),

CustomerReturns AS (
    SELECT 
        sr_ticket_number AS return_ticket,
        SUM(sr_return_quantity) AS total_returned_qty 
    FROM 
        store_returns 
    GROUP BY 
        sr_ticket_number
),

SalesWithReturns AS (
    SELECT 
        sd.ws_order_number AS order_number,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(cr.total_returned_qty, 0) AS total_returned_qty,
        sd.total_quantity - COALESCE(cr.total_returned_qty, 0) AS net_sales_quantity,
        (sd.total_sales - (COALESCE(cr.total_returned_qty, 0) * sd.total_sales / NULLIF(sd.total_quantity, 0))) AS net_sales_amount
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerReturns cr ON sd.ws_order_number = cr.return_ticket
)

SELECT 
    s.order_number,
    s.total_quantity,
    s.total_sales, 
    s.total_returned_qty,
    s.net_sales_quantity,
    s.net_sales_amount,
    ROW_NUMBER() OVER (ORDER BY s.net_sales_amount DESC) AS rank,
    CASE 
        WHEN s.net_sales_quantity > 100 THEN 'High Volume'
        WHEN s.net_sales_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM 
    SalesWithReturns s
WHERE 
    s.net_sales_amount > 0
ORDER BY 
    s.net_sales_amount DESC
LIMIT 100;

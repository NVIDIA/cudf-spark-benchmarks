
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_paid,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) as item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_paid,
        sd.total_sales
    FROM 
        SalesData sd
    WHERE 
        sd.item_rank <= 10
),
CustomersWithReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        AVG(sr.sr_return_amt) AS avg_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_sales,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        AVG(d.avg_return_amount) AS avg_customer_return
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomersWithReturns c ON ts.ws_item_sk = c.c_customer_sk
    LEFT JOIN 
        catalog_returns cr ON ts.ws_item_sk = cr.cr_item_sk
    LEFT JOIN 
        CustomersWithReturns d ON c.c_customer_sk = d.c_customer_sk
    GROUP BY 
        ts.ws_item_sk, ts.total_quantity, ts.total_sales
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_sales,
    fr.customer_count,
    fr.total_return_amount,
    fr.avg_customer_return
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC;

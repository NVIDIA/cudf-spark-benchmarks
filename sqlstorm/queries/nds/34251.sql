
WITH  SalesCTE AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr.wr_item_sk
),
SalesData AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_ext_sales_price) AS total_sales,
        SUM(s.ss_net_profit) AS total_profit,
        COUNT(DISTINCT s.ss_ticket_number) AS sales_count
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        s.ss_item_sk
),
FinalReport AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(sd.total_sales, 0) AS store_sales,
        COALESCE(sc.total_sales, 0) AS web_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_profit, 0) + COALESCE(sc.total_profit, 0)) AS total_profit,
        (COALESCE(sd.sales_count, 0) + COALESCE(cr.return_count, 0)) AS total_transactions
    FROM 
        item i
    LEFT JOIN 
        SalesData sd ON i.i_item_sk = sd.ss_item_sk
    LEFT JOIN 
        (SELECT 
            ws.ws_item_sk,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit,
            COUNT(DISTINCT ws.ws_order_number) AS web_sales_count
         FROM 
            web_sales ws
         GROUP BY 
            ws.ws_item_sk) sc ON i.i_item_sk = sc.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.store_sales,
    f.web_sales,
    f.total_returns,
    f.total_profit,
    f.total_transactions
FROM 
    FinalReport f
WHERE 
    f.store_sales + f.web_sales > 10000
ORDER BY 
    f.total_profit DESC;

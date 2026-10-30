
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt) AS total_returned_amount, 
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
ItemSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sold_quantity, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
SalesComparison AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(cr.return_count, 0) AS return_count
    FROM 
        catalog_sales cs
    LEFT JOIN 
        CustomerReturns cr ON cs.cs_ship_customer_sk = cr.sr_customer_sk
), 
AnalyzedSales AS (
    SELECT 
        sc.cs_item_sk,
        sc.cs_order_number,
        sc.cs_sales_price,
        sc.cs_ext_sales_price,
        sc.total_returned_quantity,
        sc.total_returned_amount,
        sc.return_count,
        (sc.cs_sales_price - (sc.total_returned_amount / NULLIF(sc.return_count, 0))) AS adjusted_sales_price,
        ROW_NUMBER() OVER (PARTITION BY sc.cs_item_sk ORDER BY sc.cs_net_profit DESC) AS sales_rank
    FROM 
        SalesComparison sc
)

SELECT 
    it.i_item_id,
    it.i_item_desc,
    aas.cs_order_number,
    aas.cs_sales_price,
    aas.total_returned_quantity,
    aas.adjusted_sales_price,
    aas.sales_rank
FROM 
    AnalyzedSales aas
JOIN 
    item it ON aas.cs_item_sk = it.i_item_sk
WHERE 
    aas.sales_rank <= 5 
AND 
    aas.total_returned_quantity > 0 
ORDER BY 
    aas.adjusted_sales_price DESC;

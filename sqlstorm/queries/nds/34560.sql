
WITH  SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ext_tax,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS seq
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price,
        cs_ext_tax,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS seq
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
),
ProductReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
TotalSales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        SUM(store_sales.ss_sales_price * store_sales.ss_quantity) AS total_sales,
        SUM(store_sales.ss_ext_sales_price) AS total_ext_sales,
        COALESCE(SUM(store_returns.sr_return_quantity), 0) AS total_returns
    FROM 
        item 
    LEFT JOIN 
        store_sales ON item.i_item_sk = store_sales.ss_item_sk
    LEFT JOIN 
        store_returns ON store_sales.ss_ticket_number = store_returns.sr_ticket_number
    GROUP BY 
        item.i_item_sk, item.i_item_desc
)
SELECT 
    ps.i_item_sk,
    ps.i_item_desc,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_ext_sales, 0) AS total_ext_sales,
    COALESCE(r.total_returned, 0) AS total_returned,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_tax, 0) AS total_return_tax,
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_returned, 0)) AS net_sales
FROM 
    item ps
LEFT JOIN 
    TotalSales s ON ps.i_item_sk = s.i_item_sk
LEFT JOIN 
    ProductReturns r ON ps.i_item_sk = r.wr_item_sk
WHERE 
    ps.i_current_price > 0
ORDER BY 
    net_sales DESC
LIMIT 10;

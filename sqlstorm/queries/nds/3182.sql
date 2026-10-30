
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 AND 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        item_sales.ws_item_sk,
        i.i_item_desc,
        i.i_current_price,
        item_sales.total_quantity,
        item_sales.total_sales,
        DENSE_RANK() OVER (ORDER BY item_sales.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary item_sales
    JOIN 
        item i ON item_sales.ws_item_sk = i.i_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(*) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        ts.i_item_desc,
        ts.i_current_price,
        ts.total_quantity,
        ts.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (ts.total_sales - COALESCE(cr.total_returns, 0) * ts.i_current_price) AS net_sales
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ws_item_sk = cr.sr_item_sk
    WHERE 
        ts.sales_rank <= 10
)
SELECT 
    fr.ws_item_sk,
    fr.i_item_desc,
    fr.i_current_price,
    fr.total_quantity,
    fr.total_sales,
    fr.total_returns,
    fr.net_sales
FROM 
    FinalReport fr
ORDER BY 
    fr.net_sales DESC;

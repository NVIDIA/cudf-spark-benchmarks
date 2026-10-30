
WITH  SalesAggregate AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
BestSellingItems AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_sales,
        sa.total_quantity,
        sa.total_orders
    FROM 
        SalesAggregate sa
    WHERE 
        sa.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, wr_returning_customer_sk
),
FinalResults AS (
    SELECT 
        bsi.ws_item_sk,
        bsi.total_sales,
        bsi.total_quantity,
        cr.total_return_quantity,
        cr.total_return_amt,
        COALESCE(cr.total_return_quantity, 0) AS adj_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS adj_return_amt
    FROM 
        BestSellingItems bsi
    LEFT JOIN 
        CustomerReturns cr ON bsi.ws_item_sk = cr.wr_returning_customer_sk
)
SELECT 
    f.ws_item_sk,
    f.total_sales,
    f.total_quantity,
    f.adj_return_quantity,
    f.adj_return_amt,
    (f.total_sales - f.adj_return_amt) AS net_sales,
    CASE 
        WHEN f.total_sales = 0 THEN NULL 
        ELSE (f.adj_return_quantity * 100.0 / f.total_quantity) 
    END AS return_rate
FROM 
    FinalResults f
ORDER BY 
    f.total_sales DESC;

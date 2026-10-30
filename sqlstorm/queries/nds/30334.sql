
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
TopSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        s.order_count,
        p.p_promo_name
    FROM 
        SalesCTE s
    LEFT JOIN 
        promotion p ON s.ws_item_sk = p.p_item_sk
    WHERE 
        s.sales_rank <= 100
), 
RefundInfo AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt_inc_tax) AS total_refunds,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    ts.ws_item_sk,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count,
    COALESCE(ri.total_refunds, 0) AS total_refunds,
    COALESCE(ri.return_count, 0) AS return_count,
    CASE 
        WHEN COALESCE(ts.total_sales, 0) = 0 THEN NULL
        ELSE (COALESCE(ri.total_refunds, 0) / COALESCE(ts.total_sales, 0)) * 100 
    END AS refund_percentage,
    CASE 
        WHEN ts.order_count > 0 THEN 'Active Seller'
        ELSE 'No Sales'
    END AS seller_status
FROM 
    TopSales ts
FULL OUTER JOIN 
    RefundInfo ri ON ts.ws_item_sk = ri.wr_item_sk
ORDER BY 
    total_sales DESC;

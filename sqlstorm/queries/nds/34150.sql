
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
), TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        s.total_sales,
        s.total_orders,
        DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS sales_dense_rank
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.sales_rank <= 10
), CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
), CustomerStats AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        coalesce(cr.total_returns, 0) AS total_returns,
        coalesce(cr.total_return_amount, 0.00) AS total_return_amount,
        CASE 
            WHEN cr.total_returns > 0 THEN 'Returning'
            ELSE 'New'
        END AS customer_status
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    ti.i_item_desc,
    ti.total_sales,
    cs.total_returns,
    cs.total_return_amount,
    CASE 
        WHEN cs.total_return_amount IS NULL THEN 'No Returns'
        ELSE 'Returns Recorded'
    END AS return_status
FROM 
    CustomerStats cs
JOIN 
    TopItems ti ON cs.c_first_name LIKE 'A%' 
WHERE 
    cs.customer_status = 'Returning'
ORDER BY 
    ti.total_sales DESC, cs.total_return_amount DESC;

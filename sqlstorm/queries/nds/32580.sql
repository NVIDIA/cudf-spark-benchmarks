
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
Best_Sellers AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        s.total_sales
    FROM 
        Sales_CTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.rank <= 10
), 
Customer_Returns AS (
    SELECT 
        cr_returning_customer_sk, 
        COUNT(cr_returning_customer_sk) AS returns_count,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
), 
Top_Customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.returns_count,
        r.total_return_amount,
        RANK() OVER (ORDER BY r.total_return_amount DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        Customer_Returns r ON c.c_customer_sk = r.cr_returning_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.returns_count,
    tc.total_return_amount,
    bs.i_item_id,
    bs.i_item_desc,
    bs.total_sales
FROM 
    Top_Customers tc
LEFT JOIN 
    Best_Sellers bs ON tc.sales_rank <= 5
WHERE 
    tc.returns_count > 0 
ORDER BY 
    tc.total_return_amount DESC, 
    bs.total_sales DESC
LIMIT 50;

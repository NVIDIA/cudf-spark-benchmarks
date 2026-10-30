
WITH  sales_rank AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM 
        web_sales
), high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws_ext_sales_price) > 10000
), recent_returns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returned
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(H.total_spent, 0) as total_spent,
    COALESCE(R.total_returned, 0) as total_returned,
    CASE 
        WHEN COALESCE(H.total_spent, 0) - COALESCE(R.total_returned, 0) > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer c
LEFT JOIN 
    high_value_customers H ON c.c_customer_sk = H.c_customer_sk
LEFT JOIN 
    recent_returns R ON c.c_customer_sk = R.wr_returning_customer_sk
WHERE 
    c.c_birth_year > 1980
AND 
    c.c_preferred_cust_flag = 'Y'
ORDER BY 
    customer_value_category DESC, total_spent DESC
LIMIT 100;


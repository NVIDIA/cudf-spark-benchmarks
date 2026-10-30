
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS row_num
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
StoreInfo AS (
    SELECT 
        s_store_sk,
        s_store_name,
        AVG(ss_sales_price) AS avg_sales_price,
        SUM(CASE WHEN ss_sales_price > 0 THEN ss_quantity ELSE 0 END) AS total_quantity_sold
    FROM 
        store_sales 
    INNER JOIN 
        store ON store.s_store_sk = store_sales.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name
),
ProfitCalculation AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(returns.total_returns, 0) AS total_returns,
    COALESCE(returns.total_return_amount, 0) AS total_return_amount,
    s.s_store_name,
    s.avg_sales_price,
    sales.total_sales,
    p.total_profit
FROM 
    customer c
LEFT JOIN 
    CustomerReturns returns ON c.c_customer_sk = returns.wr_returning_customer_sk
JOIN 
    StoreInfo s ON s.s_store_sk = c.c_current_addr_sk
JOIN 
    SalesCTE sales ON sales.ws_item_sk = c.c_current_hdemo_sk
LEFT JOIN 
    ProfitCalculation p ON p.ws_item_sk = sales.ws_item_sk
WHERE 
    (c.c_birth_year > 1990 AND c.c_birth_month = 12)
    OR (c.c_email_address LIKE '%@example.com')
ORDER BY 
    sales.total_sales DESC, p.total_profit DESC
LIMIT 100;

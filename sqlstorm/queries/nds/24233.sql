WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS rnk,
        COUNT(*) OVER (PARTITION BY ws_bill_customer_sk) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
        AND ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_bill_customer_sk = ws_bill_customer_sk)
), 
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(*) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk
    FROM 
        CustomerReturns cr
    WHERE 
        cr.total_returns IS NOT NULL 
        AND cr.return_count > (
            SELECT AVG(return_count)
            FROM CustomerReturns
        )
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(CASE 
        WHEN rs.rnk = 1 THEN rs.ws_sales_price
        ELSE 0 
    END) AS top_product_sales,
    COALESCE(SUM(c_r.total_returns), 0) AS total_returns,
    c.c_birth_year,
    CASE 
        WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year < 30 THEN 'Young'
        WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year BETWEEN 30 AND 60 THEN 'Middle-aged'
        ELSE 'Senior'
    END AS age_group
FROM 
    customer c
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns c_r ON c.c_customer_sk = c_r.sr_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL 
    AND c.c_customer_sk IN (SELECT * FROM HighReturnCustomers)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_year
ORDER BY 
    top_product_sales DESC
LIMIT 10;
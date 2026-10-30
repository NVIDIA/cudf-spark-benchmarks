
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk IS NOT NULL 
    GROUP BY 
        sr_item_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        SUM(ws_net_paid) >= 1000
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RS.total_sales, 0) AS total_sales,
    COALESCE(RC.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(RC.total_returns, 0) > 0 THEN (COALESCE(RS.total_sales, 0) / COALESCE(RC.total_returns, 1))
        ELSE COALESCE(RS.total_sales, 0)
    END AS effective_sales,
    CUST.total_spent AS high_value_customers
FROM 
    item i
LEFT JOIN 
    RankedSales RS ON i.i_item_sk = RS.ws_item_sk AND RS.sales_rank = 1
LEFT JOIN 
    CustomerReturns RC ON i.i_item_sk = RC.sr_item_sk
LEFT JOIN 
    HighValueCustomers CUST ON 1 = 1
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    effective_sales DESC
LIMIT 100;

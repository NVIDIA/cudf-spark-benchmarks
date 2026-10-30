
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_by_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450050
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_spent,
        cp.total_orders,
        DENSE_RANK() OVER (ORDER BY cp.total_spent DESC) AS customer_rank
    FROM 
        CustomerPurchases cp
), 
ProductReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    tc.c_customer_sk,
    tc.total_spent,
    tc.total_orders,
    COALESCE(pr.total_returns, 0) AS total_returns,
    COALESCE(pr.total_return_amount, 0) AS total_return_amount,
    CASE
        WHEN tc.total_spent >= 1000 THEN 'High Value'
        WHEN tc.total_spent BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    MAX(rs.ws_sales_price) AS max_sales_price
FROM 
    TopCustomers tc
LEFT JOIN 
    ProductReturns pr ON tc.c_customer_sk = pr.sr_item_sk
LEFT JOIN 
    RankedSales rs ON tc.c_customer_sk = rs.ws_order_number
WHERE 
    tc.customer_rank <= 10
GROUP BY 
    tc.c_customer_sk, tc.total_spent, tc.total_orders, pr.total_returns, pr.total_return_amount
ORDER BY 
    tc.total_spent DESC;

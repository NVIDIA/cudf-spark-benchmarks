
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(COALESCE(ws.ws_sales_price, 0) - CASE WHEN ws.ws_sales_price IS NULL THEN 0 ELSE ws.ws_ext_discount_amt END) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_sales_price, 0) - ws.ws_ext_discount_amt) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count
    FROM 
        CustomerStats cs
    INNER JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rnk = 1
        AND cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
ItemReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(ir.total_returned, 0) AS total_item_returns,
    RANK() OVER (ORDER BY tc.total_spent DESC, COALESCE(ir.total_returned, 0) ASC) AS customer_rank,
    CASE 
        WHEN ir.total_returned IS NULL THEN 'No Returns'
        WHEN ir.total_returned = 0 THEN 'No Returns'
        ELSE 'Returned Items'
    END AS return_status
FROM 
    TopCustomers tc
LEFT JOIN 
    ItemReturns ir ON tc.c_customer_sk = ir.sr_item_sk
ORDER BY 
    customer_rank, return_status;

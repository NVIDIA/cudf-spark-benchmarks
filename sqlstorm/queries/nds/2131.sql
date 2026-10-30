
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_year = (SELECT MAX(d_year) FROM date_dim)
        ) - 90
    GROUP BY 
        ws_bill_customer_sk, 
        ws_item_sk, 
        ws_ship_date_sk
),
TopCustomers AS (
    SELECT 
        ws_bill_customer_sk, 
        COUNT(DISTINCT ws_item_sk) AS unique_items,
        SUM(total_sales) AS total_amount
    FROM 
        SalesData
    WHERE 
        sales_rank <= 3
    GROUP BY 
        ws_bill_customer_sk
),
ReturnsData AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(tc.unique_items, 0) AS unique_items,
    COALESCE(tc.total_amount, 0) AS total_spent,
    COALESCE(tr.total_returns, 0) AS total_returns,
    COALESCE(tr.total_return_amount, 0) AS return_amount
FROM 
    customer c
LEFT JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.ws_bill_customer_sk
LEFT JOIN 
    ReturnsData tr ON c.c_customer_sk = tr.wr_returning_customer_sk
WHERE 
    COALESCE(tc.total_amount, 0) > 1000
ORDER BY 
    total_spent DESC, 
    unique_items DESC
LIMIT 100;

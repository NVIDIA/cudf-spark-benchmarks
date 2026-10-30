
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
),
RecentReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(cr_return_quantity) AS total_returns
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_date >= CURRENT_DATE - INTERVAL '3 months'
        )
    GROUP BY 
        cr_item_sk
),
TopCustomers AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_profit) > 1000
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ws.ws_item_sk,
    COALESCE(TopCustomers.order_count, 0) AS customer_order_count,
    RankedSales.total_sales,
    COALESCE(RecentReturns.total_returns, 0) AS return_count
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    RankedSales ON ws.ws_item_sk = RankedSales.ws_item_sk
LEFT JOIN 
    RecentReturns ON ws.ws_item_sk = RecentReturns.cr_item_sk
LEFT JOIN 
    TopCustomers ON c.c_customer_sk = TopCustomers.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
    AND (RankedSales.sales_rank = 1 OR RankedSales.sales_rank IS NULL)
ORDER BY 
    ca.ca_city, return_count DESC;

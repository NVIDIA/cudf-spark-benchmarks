
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_desc 
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
StoreSalesAggregate AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss 
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(ss_inner.ss_sold_date_sk) FROM store_sales ss_inner)
    GROUP BY 
        ss.ss_store_sk
),
TopReturningCustomers AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022 ORDER BY d.d_date_sk DESC LIMIT 1)
    GROUP BY 
        wr.wr_returning_customer_sk
    HAVING 
        SUM(wr.wr_return_amt_inc_tax) > 100
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(SSA.total_net_paid) AS total_net_sales,
    AVG(RSA.ws_ext_sales_price) AS avg_web_sales,
    MAX(TRC.total_return_amt) AS max_return_amt,
    CASE 
        WHEN SUM(SSA.total_net_paid) IS NULL THEN 'no sales'
        WHEN AVG(RSA.ws_ext_sales_price) > 100.00 THEN 'high sales'
        ELSE 'normal sales'
    END AS sales_category
FROM 
    customer_address ca 
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
LEFT JOIN 
    RankedSales RSA ON c.c_customer_sk = RSA.ws_item_sk
JOIN 
    StoreSalesAggregate SSA ON c.c_current_addr_sk = SSA.ss_store_sk
LEFT JOIN 
    TopReturningCustomers TRC ON c.c_customer_sk = TRC.wr_returning_customer_sk 
WHERE 
    ca.ca_country IS NOT NULL 
    AND (ca.ca_state = 'CA' OR ca.ca_state = 'NY')
GROUP BY 
    ca.ca_city, 
    RSA.ws_ext_sales_price
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 5 
ORDER BY 
    customer_count DESC, total_net_sales DESC;


WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 1999) - 30 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 1999)
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    JOIN 
        customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        cr.cr_returning_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    COALESCE(SUM(ts.total_net_profit), 0) AS top_selling_profit,
    COALESCE(SUM(cr.total_return_amount), 0) AS total_returns
FROM 
    customer_address ca
LEFT OUTER JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT OUTER JOIN 
    TopSellingItems ts ON TRUE  
LEFT OUTER JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 0 
    AND SUM(COALESCE(ts.total_net_profit, 0)) > 1000
ORDER BY 
    top_selling_profit DESC, total_returns ASC
LIMIT 20;

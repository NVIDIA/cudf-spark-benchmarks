
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_ship_cost) AS total_return_shipping
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesData AS (
    SELECT 
        ws_ship_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_web_orders,
        SUM(ws_net_paid_inc_tax) AS total_web_sales
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
ReturnSummary AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COALESCE(SUM(cr.total_returns), 0) AS total_returns,
        COALESCE(SUM(ws.total_web_orders), 0) AS total_web_orders,
        COALESCE(SUM(ws.total_web_sales), 0) AS total_web_sales
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN 
        WebSalesData ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        ca_address_sk, ca_city, ca_state
)
SELECT 
    rs.ca_city,
    rs.ca_state,
    rs.customer_count,
    rs.total_returns,
    rs.total_web_orders,
    rs.total_web_sales,
    ROW_NUMBER() OVER (PARTITION BY rs.ca_state ORDER BY rs.total_web_sales DESC) AS rank_by_sales,
    CASE 
        WHEN rs.total_web_sales > 10000 THEN 'High'
        WHEN rs.total_web_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    ReturnSummary rs
WHERE 
    rs.customer_count > 0
ORDER BY 
    rs.ca_state, rs.total_web_sales DESC;

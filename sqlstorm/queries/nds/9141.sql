
WITH CustomerAddressCTE AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
SalesDataCTE AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_web_site_sk
),
ReturnDataCTE AS (
    SELECT 
        sr.sr_store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_store_sk
)
SELECT 
    c.city AS customer_city,
    c.state AS customer_state,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.return_count, 0) AS return_count,
    c.customer_count
FROM 
    (SELECT 
        ca.ca_city AS city, 
        ca.ca_state AS state, 
        SUM(c.customer_count) AS customer_count 
     FROM 
        CustomerAddressCTE ca 
     JOIN 
        CustomerAddressCTE c ON ca.ca_address_sk = c.ca_address_sk
     GROUP BY 
        ca.ca_city, ca.ca_state) c
LEFT JOIN 
    SalesDataCTE sd ON c.city = CAST(sd.ws_web_site_sk AS STRING)  
LEFT JOIN 
    ReturnDataCTE rd ON c.city = CAST(rd.sr_store_sk AS STRING)
ORDER BY 
    total_sales DESC, 
    customer_city, 
    customer_state;

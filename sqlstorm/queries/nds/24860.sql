
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
SalesWithReturns AS (
    SELECT 
        s.ws_item_sk,
        s.ws_order_number,
        s.ws_sales_price,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_returned_quantity,
        RANK() OVER (PARTITION BY s.ws_item_sk ORDER BY COALESCE(SUM(cr.cr_return_quantity), 0) DESC) AS return_rank
    FROM 
        RankedSales s
    LEFT JOIN 
        catalog_returns cr ON s.ws_item_sk = cr.cr_item_sk AND s.ws_order_number = cr.cr_order_number
    GROUP BY 
        s.ws_item_sk, s.ws_order_number, s.ws_sales_price
)
SELECT 
    a.ca_country,
    SUM(CASE WHEN swr.total_returned_quantity > 0 THEN swr.ws_sales_price ELSE 0 END) AS adjusted_sales_value,
    COUNT(DISTINCT cs.cc_call_center_id) AS total_call_centers,
    MAX(CASE WHEN swr.return_rank = 1 THEN swr.ws_sales_price END) AS max_sales_price
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    SalesWithReturns swr ON ws.ws_item_sk = swr.ws_item_sk AND ws.ws_order_number = swr.ws_order_number
LEFT JOIN 
    call_center cs ON cs.cc_call_center_sk = (SELECT MIN(cc.cc_call_center_sk) 
                                               FROM call_center cc 
                                               WHERE cc.cc_market_manager LIKE 'A%' AND cc.cc_closed_date_sk IS NULL)
WHERE 
    a.ca_zip LIKE '1234%' OR a.ca_country IS NULL
GROUP BY 
    a.ca_country
HAVING 
    SUM(swr.total_returned_quantity) < (SELECT COUNT(*) FROM date_dim dd WHERE dd.d_year = 2023) 
ORDER BY 
    adjusted_sales_value DESC 
LIMIT 50;

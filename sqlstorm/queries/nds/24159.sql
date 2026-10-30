
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 5000
),
FilteredReturns AS (
    SELECT 
        wr.wr_order_number,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_returned_quantity,
        COUNT(wr.wr_item_sk) AS total_returns
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_amt > 0
    GROUP BY 
        wr.wr_order_number
    HAVING 
        COUNT(wr.wr_item_sk) > 1
)
SELECT 
    ca.ca_country,
    SUM(COALESCE(ws.ws_net_paid, 0) - COALESCE(sr.sr_return_amt, 0)) AS net_sales,
    COUNT(DISTINCT CASE WHEN wr.wr_order_number IS NOT NULL THEN wr.wr_order_number END) AS unique_returns,
    AVG(CASE 
        WHEN cd.cd_gender = 'F' THEN ws.ws_net_paid 
        ELSE NULL 
    END) AS avg_sales_female_customers,
    COUNT(DISTINCT CASE 
        WHEN wr.total_returned_quantity IS NOT NULL THEN wr.wr_order_number 
        ELSE NULL 
    END) AS count_of_orders_with_returns
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    FilteredReturns wr ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN 
    store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_country IS NOT NULL
GROUP BY 
    ca.ca_country
HAVING 
    SUM(COALESCE(ws.ws_net_paid, 0) - COALESCE(sr.sr_return_amt, 0)) > 10000 
    OR COUNT(DISTINCT CASE WHEN wr.wr_order_number IS NOT NULL THEN wr.wr_order_number END) > 5
ORDER BY 
    net_sales DESC, count_of_orders_with_returns ASC
LIMIT 100;

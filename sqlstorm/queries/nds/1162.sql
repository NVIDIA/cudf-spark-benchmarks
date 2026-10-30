
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
SalesSummary AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
TopSales AS (
    SELECT 
        ss.ws_order_number,
        ss.total_quantity,
        ss.total_net_paid,
        ss.avg_sales_price
    FROM 
        SalesSummary ss
    WHERE 
        ss.total_net_paid > (SELECT AVG(total_net_paid) FROM SalesSummary)
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(tr.ws_net_profit), 0) AS total_net_profit,
    COUNT(DISTINCT tr.ws_order_number) AS orders_count,
    MAX(ts.avg_sales_price) AS max_avg_sales_price
FROM 
    TopSales ts
JOIN 
    web_sales ws ON ts.ws_order_number = ws.ws_order_number
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales tr ON ws.ws_order_number = tr.ws_order_number
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
HAVING 
    SUM(tr.ws_net_profit) > 1000 
ORDER BY 
    total_net_profit DESC, orders_count ASC;

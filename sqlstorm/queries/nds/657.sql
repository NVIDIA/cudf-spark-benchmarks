
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit
    FROM SalesData sd
    WHERE sd.rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_sales_price) AS customer_total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerSegment AS (
    SELECT 
        cs.c_customer_sk,
        CASE 
            WHEN cs.customer_total_spent > 1000 THEN 'High Value'
            WHEN cs.customer_total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM CustomerSales cs
)
SELECT 
    ca.ca_city, 
    cs.customer_segment, 
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
    SUM(ts.total_quantity) AS total_items_sold,
    SUM(ts.total_profit) AS total_profit_generated
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN CustomerSegment cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN TopSales ts ON c.c_current_cdemo_sk = ts.ws_item_sk
GROUP BY ca.ca_city, cs.customer_segment
ORDER BY ca.ca_city, cs.customer_segment;

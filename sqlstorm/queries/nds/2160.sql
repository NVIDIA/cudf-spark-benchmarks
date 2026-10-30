
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
HighValueItems AS (
    SELECT 
        i.i_item_id,
        ss.total_quantity_sold,
        ss.total_sales,
        ss.total_net_profit
    FROM 
        SalesSummary ss 
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.total_net_profit > 1000
),
FrequentCustomers AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 5
)
SELECT 
    hvi.i_item_id,
    hvi.total_quantity_sold,
    hvi.total_sales,
    hvi.total_net_profit,
    fc.c_customer_id,
    fc.order_count
FROM 
    HighValueItems hvi
INNER JOIN 
    FrequentCustomers fc ON hvi.total_quantity_sold > (SELECT AVG(total_quantity_sold) FROM HighValueItems)
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk IS NOT NULL 
WHERE 
    hvi.total_sales > (SELECT AVG(total_sales) FROM HighValueItems)
ORDER BY 
    hvi.total_net_profit DESC, 
    fc.order_count DESC
LIMIT 100;

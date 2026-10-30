
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_coupon_amt,
        ws.ws_net_profit,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_coupon_amt,
        sd.ws_net_profit,
        sd.d_date
    FROM 
        SalesData sd
    WHERE 
        sd.rn <= 5
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ts.ws_item_sk) AS top_items_sold,
    AVG(ts.ws_sales_price) AS avg_sales_price,
    SUM(cs.total_net_profit) AS overall_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    TopSales ts ON ts.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 20)
LEFT JOIN 
    CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(cs.total_orders) > 10
ORDER BY 
    overall_net_profit DESC;

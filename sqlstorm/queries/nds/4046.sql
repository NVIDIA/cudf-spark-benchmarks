
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
),
TotalSalesByCustomer AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.ws_bill_customer_sk
),
SalesBreakdown AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_net_profit) AS state_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_order_value,
        MAX(ws.ws_net_profit) AS max_order_value
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    rs.ws_item_sk,
    rs.ws_order_number,
    rs.ws_quantity,
    rs.ws_sales_price,
    ts.total_net_profit,
    sb.state_net_profit,
    sb.total_orders,
    sb.average_order_value
FROM 
    RankedSales rs
LEFT JOIN 
    TotalSalesByCustomer ts ON rs.ws_order_number = ts.ws_bill_customer_sk
JOIN 
    SalesBreakdown sb ON sb.state_net_profit > 1000
WHERE 
    rs.rank <= 10 
    AND rs.ws_net_profit IS NOT NULL
ORDER BY 
    sb.state_net_profit DESC, 
    rs.ws_sales_price DESC;

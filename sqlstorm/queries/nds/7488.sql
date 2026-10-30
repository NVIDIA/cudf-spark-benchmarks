
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
), TopCustomers AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT rs.ws_bill_customer_sk) AS customer_count,
        SUM(rs.total_profit) AS city_profit
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        RankedSales rs ON rs.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    ca_city,
    ca_state,
    customer_count,
    city_profit,
    RANK() OVER (ORDER BY city_profit DESC) AS city_profit_rank
FROM 
    TopCustomers
WHERE 
    customer_count > 10
ORDER BY 
    city_profit DESC
LIMIT 10;

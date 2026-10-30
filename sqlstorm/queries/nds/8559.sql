
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231 
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        rs.profit_rank <= 10
),
CustomerAddress AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_customer_sk IN (SELECT ws_bill_customer_sk FROM RankedSales)
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    ca.ca_city,
    ca.ca_state,
    ca.address_count
FROM 
    TopCustomers tc
JOIN 
    CustomerAddress ca ON ca.ca_city IN (SELECT ca_city FROM CustomerAddress WHERE address_count > 5)
ORDER BY 
    tc.total_profit DESC;

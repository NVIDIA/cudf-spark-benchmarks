
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),
CustomerAddresses AS (
    SELECT
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    hs.order_count,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    HighSpenders hs
JOIN 
    CustomerAddresses ca ON hs.c_customer_sk = ca.c_customer_sk
WHERE 
    hs.sales_rank <= 10
ORDER BY 
    hs.total_spent DESC;

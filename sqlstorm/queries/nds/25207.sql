
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
),

RankedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.full_name,
        cs.ca_city,
        cs.ca_state,
        cs.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.ca_state ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)

SELECT 
    rc.full_name,
    rc.ca_city,
    rc.ca_state,
    rc.total_sales
FROM 
    RankedCustomers rc
WHERE 
    rc.sales_rank <= 5
ORDER BY 
    rc.ca_state, rc.sales_rank;

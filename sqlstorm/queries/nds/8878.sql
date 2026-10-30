
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
        SUM(cs.total_sales) AS total_state_sales
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY 
        ca.ca_state
),
ranked_sales AS (
    SELECT 
        ss.ca_state,
        ss.num_customers,
        ss.total_state_sales,
        RANK() OVER (ORDER BY ss.total_state_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    r.ca_state,
    r.num_customers,
    r.total_state_sales,
    r.sales_rank
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;

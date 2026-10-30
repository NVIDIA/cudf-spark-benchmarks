
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ci.total_sales,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY ci.total_sales DESC) AS sales_rank
    FROM 
        customer_info AS ci
    JOIN 
        customer AS c ON ci.c_customer_id = c.c_customer_id
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
state_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT tc.c_customer_id) AS customer_count,
        SUM(tc.total_sales) AS state_sales_total,
        AVG(tc.total_sales) AS avg_sales_per_customer
    FROM 
        top_customers AS tc
    JOIN 
        customer_address AS ca ON tc.c_customer_id = ca.ca_address_id
    WHERE 
        tc.sales_rank <= 10
    GROUP BY 
        ca.ca_state
)
SELECT 
    s.ca_state,
    ss.customer_count,
    ss.state_sales_total,
    ss.avg_sales_per_customer
FROM 
    state_summary AS ss
JOIN 
    customer_address AS s ON ss.ca_state = s.ca_state
ORDER BY 
    ss.state_sales_total DESC;

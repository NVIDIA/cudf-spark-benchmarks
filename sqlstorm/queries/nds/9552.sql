
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_country,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_country = 'USA'
    GROUP BY 
        c.c_customer_sk, ca.ca_country
),
top_customers AS (
    SELECT 
        c_customer_sk,
        total_sales,
        order_count,
        avg_sales_price,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        tc.total_sales,
        tc.order_count,
        tc.avg_sales_price
    FROM 
        top_customers tc
    JOIN 
        customer c ON tc.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    COUNT(*) AS customer_count,
    SUM(tc.total_sales) AS total_sales,
    AVG(tc.avg_sales_price) AS avg_sales_price_per_gender
FROM 
    customer_demographics cd
JOIN 
    top_customers tc ON cd.total_sales = tc.total_sales
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales DESC;

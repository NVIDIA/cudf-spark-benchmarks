WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_birth_year,
        ca.ca_city
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2001 AND d_month_seq IN (1, 2, 3)  
        )
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, c.c_birth_year, ca.ca_city
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    ca.ca_city,
    AVG(total_sales) AS average_sales,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(CASE WHEN sales_rank <= 10 THEN total_sales ELSE 0 END) AS top_customer_sales
FROM 
    RankedSales
JOIN 
    customer_address ca ON RankedSales.c_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    average_sales DESC
LIMIT 10;
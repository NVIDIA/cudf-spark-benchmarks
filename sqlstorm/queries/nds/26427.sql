
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        ca.ca_state IN ('CA', 'NY', 'TX')
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        CustomerInfo ci ON ss.ss_customer_sk = ci.c_customer_sk
    GROUP BY 
        ss.ss_store_sk
),
TopStores AS (
    SELECT 
        s.s_store_name AS store_name, 
        s.s_city, 
        s.s_state,
        ss.total_sales, 
        ss.unique_customers,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        StoreSales ss ON s.s_store_sk = ss.ss_store_sk
)
SELECT 
    store_name,
    s_city,
    s_state,
    total_sales,
    unique_customers,
    sales_rank
FROM 
    TopStores
WHERE 
    sales_rank <= 10
ORDER BY 
    total_sales DESC;

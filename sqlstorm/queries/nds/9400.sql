
WITH RankedSales AS (
    SELECT 
        s.s_store_id, 
        SUM(ss.ss_quantity) AS total_quantity, 
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2000 AND 
        d.d_moy IN (11, 12) 
    GROUP BY 
        s.s_store_id
),
TopStores AS (
    SELECT 
        s_store_id AS store_id, 
        total_quantity, 
        total_sales 
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 5
)
SELECT 
    ts.store_id,
    ca.ca_city,
    ca.ca_state,
    ts.total_quantity,
    ts.total_sales,
    COUNT(DISTINCT cs.ss_customer_sk) AS unique_customers
FROM 
    TopStores ts
JOIN 
    store s ON ts.store_id = s.s_store_id
JOIN 
    customer_address ca ON s.s_store_sk = ca.ca_address_sk
JOIN 
    store_sales cs ON s.s_store_sk = cs.ss_store_sk
GROUP BY 
    ts.store_id, ca.ca_city, ca.ca_state, ts.total_quantity, ts.total_sales
ORDER BY 
    ts.total_sales DESC;


WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ss_store_sk
),
TopStores AS (
    SELECT 
        rs.ss_store_sk,
        rs.total_sales,
        rs.transaction_count,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country
    FROM 
        RankedSales rs
    JOIN 
        store s ON rs.ss_store_sk = s.s_store_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ts.s_store_name,
    ts.s_city,
    ts.s_state,
    ts.s_country,
    cs.c_customer_sk,
    cs.total_spent,
    cs.total_purchases,
    ts.total_sales
FROM 
    TopStores ts
JOIN 
    CustomerSales cs ON cs.total_spent > (SELECT AVG(total_sales) FROM RankedSales)
ORDER BY 
    ts.total_sales DESC, cs.total_spent DESC;

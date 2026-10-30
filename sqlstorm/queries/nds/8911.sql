
WITH RankedSales AS (
    SELECT 
        s.s_store_id, 
        s.s_store_name, 
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        store s 
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk 
    WHERE 
        ss.ss_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq IN (6, 7)
        )
    GROUP BY 
        s.s_store_id, 
        s.s_store_name
), 
TopStores AS (
    SELECT 
        rs.s_store_id, 
        rs.s_store_name, 
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
), 
CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ss.ss_net_paid) AS customer_total_sales
    FROM 
        customer c 
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    WHERE 
        ss.ss_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq IN (6, 7)
        )
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ts.s_store_name,
    cs.c_customer_id,
    cs.customer_total_sales,
    ts.total_sales AS store_total_sales,
    (cs.customer_total_sales / NULLIF(ts.total_sales, 0)) * 100 AS customer_percentage_of_store_sales
FROM 
    TopStores ts
JOIN 
    CustomerSales cs ON cs.customer_total_sales > (0.1 * ts.total_sales)
ORDER BY 
    ts.s_store_name, 
    cs.customer_total_sales DESC;


WITH SalesSummary AS (
    SELECT 
        s_store_name,
        d_year,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_sales_price) AS avg_sales_price
    FROM 
        store_sales
    JOIN 
        store ON ss_store_sk = s_store_sk
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2021 AND 2023
    GROUP BY 
        s_store_name, d_year
),
CustomerSummary AS (
    SELECT 
        c_first_name,
        c_last_name,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY 
        c_first_name, c_last_name
    HAVING 
        SUM(ws_net_paid) > 1000
),
TopStores AS (
    SELECT 
        s_store_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
    WHERE 
        d_year = 2023
)
SELECT 
    ts.s_store_name, 
    ts.total_sales,
    cs.c_first_name, 
    cs.c_last_name, 
    cs.total_spent
FROM 
    TopStores ts
JOIN 
    CustomerSummary cs ON ts.total_sales > cs.total_spent
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC, 
    cs.total_spent DESC;

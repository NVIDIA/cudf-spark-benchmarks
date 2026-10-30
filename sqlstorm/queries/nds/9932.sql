
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND ca.ca_state IN ('CA', 'NY', 'TX')
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state
),
RankedSales AS (
    SELECT 
        css.c_customer_id,
        css.ca_city,
        css.ca_state,
        css.total_sales,
        css.total_transactions,
        css.avg_sales_price,
        RANK() OVER (PARTITION BY css.ca_state ORDER BY css.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary css
)
SELECT 
    r.c_customer_id,
    r.ca_city,
    r.ca_state,
    r.total_sales,
    r.total_transactions,
    r.avg_sales_price
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.ca_state, r.total_sales DESC;

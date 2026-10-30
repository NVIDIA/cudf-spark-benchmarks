
WITH SalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        ca.ca_state,
        d.d_year
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ss.ss_item_sk, ca.ca_state, d.d_year
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.ca_state ORDER BY sd.total_sales DESC) as sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.ca_state,
    rs.total_quantity,
    rs.total_sales,
    rs.unique_customers,
    rs.sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.ca_state, rs.sales_rank;

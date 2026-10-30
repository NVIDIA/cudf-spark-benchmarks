
WITH  SalesCTE AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    JOIN 
        store ON store_sales.ss_store_sk = store.s_store_sk
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        s_store_sk,
        s_store_name
), 
RankedSales AS (
    SELECT 
        s_store_name,
        total_sales,
        total_transactions,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesCTE
),
CustomerStats AS (
    SELECT 
        ca_country,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    LEFT JOIN 
        customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
    GROUP BY 
        ca_country
)
SELECT 
    rs.s_store_name,
    rs.total_sales,
    rs.total_transactions,
    cs.ca_country,
    cs.customer_count,
    cs.avg_purchase_estimate
FROM 
    RankedSales rs
LEFT OUTER JOIN 
    CustomerStats cs ON cs.customer_count > 0
WHERE 
    rs.sales_rank <= 10 
ORDER BY 
    rs.total_sales DESC;

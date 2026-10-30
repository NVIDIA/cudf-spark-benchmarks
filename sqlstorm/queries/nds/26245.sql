
WITH CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        REPLACE(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type), ' ', '-') AS formatted_address
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_sales_price) AS total_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),
RankedSales AS (
    SELECT 
        s.s_store_id,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        StoreSales ss ON s.s_store_sk = ss.ss_store_sk
),
ReturnInfo AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(*) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ca.full_name,
    ca.ca_city,
    ca.ca_state,
    ca.formatted_address,
    rs.sales_rank,
    COALESCE(ri.total_returns, 0) AS total_returns
FROM 
    CustomerAddresses ca
JOIN 
    RankedSales rs ON rs.sales_rank < 5
LEFT JOIN 
    ReturnInfo ri ON ri.cr_item_sk = ca.ca_address_sk
ORDER BY 
    ca.ca_city, ca.full_name;

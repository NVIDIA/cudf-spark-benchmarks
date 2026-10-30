
WITH  SalesCTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales,
        ss_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk, 
        ss_sold_date_sk
),
RankedSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(sales.total_sales), 0) AS total_sales
    FROM 
        item
    LEFT JOIN 
        SalesCTE sales ON item.i_item_sk = sales.ss_item_sk
    GROUP BY 
        item.i_item_id, 
        item.i_item_desc
),
TopSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RankedSales
)
SELECT 
    customer.c_customer_id,
    customer.c_first_name,
    customer.c_last_name,
    address.ca_city,
    address.ca_state,
    sales.i_item_desc,
    sales.total_sales
FROM 
    customer
JOIN 
    customer_address address ON customer.c_current_addr_sk = address.ca_address_sk
LEFT JOIN 
    TopSales sales ON sales.total_sales > 10000
WHERE 
    customer.c_birth_year BETWEEN 1980 AND 1990
    AND address.ca_state IN ('CA', 'NY')
ORDER BY 
    sales.total_sales DESC
LIMIT 50;


WITH  address_stats AS (
    SELECT 
        ca_address_sk,
        ca_city,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_address 
    LEFT JOIN 
        customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
    GROUP BY 
        ca_address_sk, ca_city
),
sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS item_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
return_stats AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr_item_sk
)
SELECT 
    a.ca_city,
    COALESCE(a.customer_count, 0) AS customer_count,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(a.customer_count, 0) = 0 THEN 'No customers'
        ELSE 'Customers present'
    END AS customer_presence,
    CASE 
        WHEN (COALESCE(s.total_sales - r.total_returns, 0)) > 10000 THEN 'High Sales'
        ELSE 'Normal Sales'
    END AS sales_performance,
    DENSE_RANK() OVER (ORDER BY (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) DESC) AS sales_rank
FROM 
    address_stats a
LEFT JOIN 
    sales_summary s ON s.ws_item_sk = a.ca_address_sk
LEFT JOIN 
    return_stats r ON r.cr_item_sk = s.ws_item_sk
ORDER BY 
    net_sales DESC
LIMIT 10;


WITH SalesSummary AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_order_number,
        p.p_promo_name,
        c.c_customer_id,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        p.p_discount_active = 'Y' 
        AND d.d_year = 2023
),
FilteredSales AS (
    SELECT 
        c_customer_id AS customer_id,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        SalesSummary
    WHERE 
        sales_rank <= 5
    GROUP BY 
        c_customer_id
)
SELECT 
    fs.customer_id,
    fs.total_sales,
    fs.order_count,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.web_site_sk) AS websites
FROM 
    FilteredSales fs
LEFT JOIN 
    customer c ON fs.customer_id = c.c_customer_id
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_site ws ON c.c_email_address LIKE '%' || ws.web_name || '%'
WHERE 
    fs.total_sales IS NOT NULL 
    AND fs.order_count > 0
GROUP BY 
    fs.customer_id, fs.total_sales, fs.order_count, ca.ca_city, ca.ca_state
ORDER BY 
    fs.total_sales DESC
LIMIT 100;

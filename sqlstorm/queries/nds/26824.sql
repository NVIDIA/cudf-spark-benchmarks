
WITH FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'S' 
        AND cd.cd_gender = 'F'
        AND cd.cd_education_status LIKE '%Bachelor%'
),
RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        fc.c_customer_sk,
        fc.full_name,
        fc.ca_city,
        fc.ca_state,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rs.order_count, 0) AS order_count
    FROM 
        FilteredCustomers fc
    LEFT JOIN 
        RecentSales rs ON fc.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    cs.full_name,
    cs.ca_city,
    cs.ca_state,
    cs.total_sales,
    cs.order_count,
    RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
FROM 
    CustomerSales cs
ORDER BY 
    cs.total_sales DESC
LIMIT 10;

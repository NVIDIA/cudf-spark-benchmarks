
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.total_orders, 0) AS total_orders,
    RANK() OVER (ORDER BY COALESCE(rs.total_sales, 0) DESC) AS sales_rank
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    cd.cd_gender IS NOT NULL
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S')
    AND (cd.ca_state IS NOT NULL OR cd.ca_city IS NOT NULL)
UNION ALL
SELECT 
    'Total' AS c_first_name,
    NULL AS c_last_name,
    NULL AS ca_city,
    NULL AS ca_state,
    SUM(COALESCE(rs.total_sales, 0)) AS total_sales,
    SUM(COALESCE(rs.total_orders, 0)) AS total_orders,
    NULL AS sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.total_sales > 1000
ORDER BY 
    total_sales DESC;

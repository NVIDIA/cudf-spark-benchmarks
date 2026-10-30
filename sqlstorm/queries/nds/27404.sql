
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        ca_city, 
        COUNT(*) AS address_count 
    FROM 
        customer_address 
    GROUP BY 
        ca_state, 
        ca_city
), 
CustomerCounts AS (
    SELECT 
        cd_marital_status, 
        COUNT(DISTINCT c_customer_sk) AS customer_count 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    GROUP BY 
        cd_marital_status
), 
SalesStats AS (
    SELECT 
        d.d_year AS year, 
        SUM(ws_ext_sales_price) AS total_sales, 
        SUM(ws_ext_discount_amt) AS total_discount 
    FROM 
        web_sales 
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk 
    GROUP BY 
        d.d_year
),
DetailedInfo AS (
    SELECT 
        a.ca_state, 
        a.ca_city, 
        ac.address_count, 
        cc.cd_marital_status, 
        cc.customer_count, 
        ss.total_sales, 
        ss.total_discount 
    FROM 
        AddressCounts ac 
    JOIN 
        CustomerCounts cc ON 1 = 1 
    LEFT JOIN 
        SalesStats ss ON ss.year = EXTRACT(YEAR FROM DATE '2002-10-01')  
    LEFT JOIN 
        customer_address a ON a.ca_state = ac.ca_state AND a.ca_city = ac.ca_city
)
SELECT 
    ca_state, 
    ca_city, 
    address_count, 
    cd_marital_status, 
    customer_count, 
    total_sales, 
    total_discount 
FROM 
    DetailedInfo 
ORDER BY 
    address_count DESC, 
    customer_count DESC;


WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighRevenueItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_revenue,
        i.i_item_desc,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON i.i_item_sk = c.c_current_cdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rs.rank <= 10
),
TopCities AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_city
    ORDER BY 
        customer_count DESC
    LIMIT 5
)
SELECT 
    hri.i_item_desc,
    hri.total_quantity,
    hri.total_revenue,
    tc.ca_city,
    tc.customer_count
FROM 
    HighRevenueItems hri
JOIN 
    TopCities tc ON tc.customer_count > 100
ORDER BY 
    hri.total_revenue DESC, 
    tc.customer_count DESC
LIMIT 20;

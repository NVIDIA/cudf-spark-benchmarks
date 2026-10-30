
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458476 AND 2458477  
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, ca.ca_state
),
RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.total_sales,
        c.total_orders,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_purchase_estimate,
        c.ca_state,
        DENSE_RANK() OVER (PARTITION BY c.ca_state ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    rs.ca_state,
    rs.cd_gender,
    rs.cd_marital_status,
    AVG(rs.total_sales) AS avg_sales,
    COUNT(*) AS customer_count,
    SUM(rs.total_orders) AS total_orders
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10  
GROUP BY 
    rs.ca_state, rs.cd_gender, rs.cd_marital_status
ORDER BY 
    rs.ca_state, avg_sales DESC;

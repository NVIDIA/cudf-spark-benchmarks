
WITH CustomerSalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state
),
CitySalesRanking AS (
    SELECT 
        ca_city,
        ca_state,
        SUM(total_sales) AS city_sales,
        AVG(avg_net_profit) AS avg_profit,
        RANK() OVER (PARTITION BY ca_state ORDER BY SUM(total_sales) DESC) AS city_rank
    FROM 
        CustomerSalesData
    GROUP BY 
        ca_city, ca_state
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.avg_net_profit,
    csr.city_sales,
    csr.city_rank
FROM 
    CustomerSalesData cs
JOIN 
    CitySalesRanking csr ON cs.ca_city = csr.ca_city AND cs.ca_state = csr.ca_state
WHERE 
    csr.city_rank <= 5
ORDER BY 
    cs.total_sales DESC;

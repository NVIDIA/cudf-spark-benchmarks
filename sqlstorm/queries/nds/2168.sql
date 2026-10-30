
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        SUM(ws.ws_net_paid_inc_tax) AS total_spend,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city
),
TopCities AS (
    SELECT 
        ca.ca_city,
        AVG(cs.total_spend) AS avg_spend
    FROM 
        CustomerSummary cs
    JOIN 
        customer_address ca ON ca.ca_city = cs.ca_city
    GROUP BY 
        ca.ca_city
    HAVING 
        COUNT(DISTINCT cs.c_customer_id) > 10
),
CustomerRanked AS (
    SELECT 
        cs.*,
        ROW_NUMBER() OVER (ORDER BY cs.total_spend DESC) AS overall_rank
    FROM 
        CustomerSummary cs
    WHERE 
        cs.total_spend > (SELECT AVG(avg_spend) FROM TopCities)
)
SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    cr.total_spend,
    cr.city_rank,
    tc.avg_spend
FROM 
    CustomerRanked cr
LEFT JOIN 
    TopCities tc ON cr.ca_city = tc.ca_city
WHERE 
    cr.overall_rank <= 100
ORDER BY 
    cr.total_spend DESC;

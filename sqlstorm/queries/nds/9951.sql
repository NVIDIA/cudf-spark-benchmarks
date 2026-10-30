
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        hd.hd_income_band_sk,
        hd.hd_buy_potential, 
        c.c_birth_year, 
        c.c_current_addr_sk,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        hd.hd_income_band_sk,
        hd.hd_buy_potential, 
        c.c_birth_year, 
        c.c_current_addr_sk,
        ca.ca_state
),
AggregateStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS num_customers,
        AVG(total_spent) AS avg_spent,
        AVG(total_orders) AS avg_orders
    FROM 
        CustomerDetails
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state AS State,
    a.num_customers AS NumberOfCustomers,
    a.avg_spent AS AverageSpent,
    a.avg_orders AS AverageOrders,
    ROW_NUMBER() OVER (ORDER BY a.avg_spent DESC) AS RankBySpending
FROM 
    AggregateStats a
WHERE 
    a.num_customers > 0
ORDER BY 
    a.avg_spent DESC;

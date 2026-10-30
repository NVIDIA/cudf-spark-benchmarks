
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        cs.total_revenue,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cs.total_profit > 1000 AND cs.total_orders > 5
), 
DateRange AS (
    SELECT 
        d.d_date_sk, 
        d.d_year 
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
), 
SalesSummary AS (
    SELECT 
        dr.d_year,
        SUM(c.total_revenue) AS year_revenue,
        COUNT(c.c_customer_sk) AS number_of_customers
    FROM 
        DateRange dr
    JOIN 
        web_sales ws ON dr.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        HighValueCustomers c ON ws.ws_ship_customer_sk = c.c_customer_sk 
    GROUP BY 
        dr.d_year
)
SELECT 
    ss.d_year, 
    ss.year_revenue, 
    ss.number_of_customers,
    ROUND(ss.year_revenue / NULLIF(ss.number_of_customers, 0), 2) AS avg_revenue_per_customer
FROM 
    SalesSummary ss
ORDER BY 
    ss.year_revenue DESC;

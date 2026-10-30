
WITH AnnualSales AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_credit_rating,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_credit_rating IS NOT NULL
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, cd_credit_rating
    HAVING 
        SUM(ws_net_paid) > 10000
),
MonthlySales AS (
    SELECT 
        d_month_seq AS month,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS items_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_ship_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
    GROUP BY 
        d_month_seq
),
DeclinedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    WHERE 
        cr_return_amount < 0 
    GROUP BY 
        cr_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    COALESCE(SUM(m.total_sales), 0) AS monthly_sales,
    COALESCE(hvc.total_spent, 0) AS high_value_spent,
    COALESCE(SUM(dr.total_returns), 0) AS total_declined_returns
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    MonthlySales m ON EXTRACT(MONTH FROM DATE '2002-10-01') = m.month
LEFT JOIN 
    HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN 
    DeclinedReturns dr ON c.c_customer_sk = dr.cr_item_sk
WHERE 
    ca.ca_state IN ('NY', 'CA') 
    AND (c.c_birth_year IS NULL OR c.c_birth_year BETWEEN 1980 AND 1990)
GROUP BY 
    ca.ca_city, hvc.total_spent
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5 
    AND (COALESCE(SUM(m.total_sales), 0) > 5000 OR COALESCE(hvc.total_spent, 0) > 5000)
ORDER BY 
    customer_count DESC, monthly_sales DESC;


WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_ship_mode_sk
),
DateSummary AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(rs.total_quantity) AS monthly_total_quantity,
        SUM(rs.total_net_paid) AS monthly_total_net_paid
    FROM 
        RankedSales rs
    JOIN 
        date_dim dd ON rs.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        rs.rank <= 5
    GROUP BY 
        dd.d_year, dd.d_month_seq
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        COUNT(cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(cs.cs_net_paid) > 1000
)
SELECT 
    ds.d_year,
    ds.d_month_seq,
    ds.monthly_total_quantity,
    ds.monthly_total_net_paid,
    tc.c_customer_id,
    tc.total_orders,
    tc.total_spent
FROM 
    DateSummary ds
LEFT JOIN 
    TopCustomers tc ON ds.monthly_total_net_paid > 5000
ORDER BY 
    ds.d_year, ds.d_month_seq, tc.total_spent DESC;

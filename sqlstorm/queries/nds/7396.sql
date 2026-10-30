
WITH SalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_sales_price) AS average_sales_price,
        d.d_year,
        d.d_month_seq,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ss.ss_item_sk, 
        d.d_year, 
        d.d_month_seq, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state
),
TopSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales_quantity DESC) AS rank_quantity,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rank_net_paid
    FROM 
        SalesData
)
SELECT 
    ts.d_year,
    ts.d_month_seq,
    ts.c_first_name,
    ts.c_last_name,
    ts.ca_city,
    ts.ca_state,
    ts.total_sales_quantity,
    ts.total_net_paid,
    ts.average_sales_price
FROM 
    TopSales ts
WHERE 
    ts.rank_quantity <= 10 OR ts.rank_net_paid <= 10
ORDER BY 
    ts.d_year, 
    ts.rank_quantity, 
    ts.rank_net_paid;

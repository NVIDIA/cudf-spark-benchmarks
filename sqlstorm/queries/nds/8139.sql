WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_sales_price) AS total_revenue,
        SUM(ss.ss_quantity) AS total_quantity
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 1998 AND 2001
    GROUP BY 
        d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
inventory_summary AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    s.sales_year,
    s.sales_month,
    s.total_sales,
    s.total_revenue,
    s.total_quantity,
    c.cd_gender,
    c.cd_marital_status,
    c.avg_purchase_estimate,
    c.customer_count,
    i.total_inventory
FROM 
    sales_summary s
JOIN 
    customer_summary c ON s.sales_year >= 1999 
JOIN 
    inventory_summary i ON s.sales_year IN (1998, 1999, 2000, 2001) 
ORDER BY 
    s.sales_year, s.sales_month, c.cd_gender;
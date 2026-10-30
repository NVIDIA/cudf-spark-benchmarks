
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        w.w_warehouse_name
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT 
    sd.w_warehouse_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    SUM(sd.total_quantity_sold) AS total_quantity_sold,
    SUM(sd.total_sales) AS total_sales,
    AVG(ci.total_purchases) AS avg_purchases_per_customer
FROM 
    SalesData sd
JOIN 
    CustomerInfo ci ON sd.total_transactions > 0
GROUP BY 
    sd.w_warehouse_name, ci.cd_gender, ci.cd_marital_status, ci.cd_credit_rating
ORDER BY 
    total_sales DESC
LIMIT 10;

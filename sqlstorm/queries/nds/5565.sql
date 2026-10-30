
WITH SalesData AS (
    SELECT 
        s.s_store_name, 
        SUM(ss.ss_quantity) AS total_quantity_sold, 
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.s_store_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(sd.total_quantity_sold) AS total_quantity_sold,
        SUM(sd.total_net_paid) AS total_net_paid
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.s_store_name = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    SUM(cd.total_quantity_sold) AS overall_quantity_sold, 
    SUM(cd.total_net_paid) AS overall_net_paid,
    AVG(cd.total_net_paid / NULLIF(cd.total_quantity_sold, 0)) AS avg_order_value
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    overall_net_paid DESC;

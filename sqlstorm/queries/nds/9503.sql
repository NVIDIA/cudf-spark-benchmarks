
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        MAX(cs.cs_sold_date_sk) AS last_sale_date
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.cs_order_number) AS purchase_count,
        SUM(cs.cs_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), 
RankedSales AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY sd.total_net_paid DESC) AS rank_per_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY sd.total_net_paid DESC) AS rank_per_marital_status
    FROM 
        SalesData sd
    JOIN 
        CustomerData cd ON sd.cs_item_sk = cd.c_customer_sk
)

SELECT 
    rs.cs_item_sk,
    rs.total_quantity,
    rs.total_net_paid,
    rs.c_customer_sk,
    rs.cd_gender,
    rs.cd_marital_status
FROM 
    RankedSales rs
WHERE 
    (rs.rank_per_gender <= 10 OR rs.rank_per_marital_status <= 10)
ORDER BY 
    rs.cd_gender, rs.total_net_paid DESC;

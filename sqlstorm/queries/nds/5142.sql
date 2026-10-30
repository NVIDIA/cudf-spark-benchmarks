
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_sales_price - cs.cs_ext_discount_amt) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        cs.cs_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.cs_order_number) AS customer_order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
ItemData AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        sd.total_sales,
        sd.total_profit,
        sd.order_count
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.cs_item_sk
)
SELECT 
    id.i_item_desc,
    id.i_category,
    id.i_brand,
    SUM(cd.customer_order_count) AS total_customers_ordered,
    AVG(id.total_sales) AS avg_sales_per_item,
    AVG(id.total_profit) AS avg_profit_per_item
FROM 
    ItemData id
LEFT JOIN 
    CustomerData cd ON id.i_item_sk = cd.c_customer_sk
GROUP BY 
    id.i_item_desc, id.i_category, id.i_brand
ORDER BY 
    avg_sales_per_item DESC
LIMIT 10;

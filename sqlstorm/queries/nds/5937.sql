
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS sales_rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20.00
        AND cs.cs_sold_date_sk BETWEEN 20230101 AND 20231231
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd.cd_gender = 'F'
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    i.i_item_id,
    SUM(rs.cs_quantity) AS total_quantity_sold,
    SUM(rs.cs_ext_sales_price) AS total_sales_value,
    AVG(cd.avg_purchase_estimate) AS average_estimate,
    COUNT(DISTINCT cd.cd_demo_sk) AS unique_customers
FROM 
    RankedSales rs
JOIN 
    item i ON rs.cs_item_sk = i.i_item_sk
JOIN 
    CustomerDemographics cd ON rs.cs_item_sk IN (
        SELECT cs.cs_item_sk 
        FROM catalog_sales cs 
        WHERE cs.cs_order_number IN (SELECT DISTINCT cs_order_number FROM RankedSales)
    )
WHERE 
    rs.sales_rank = 1
GROUP BY 
    i.i_item_id, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales_value DESC
LIMIT 10;

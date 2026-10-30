WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450206 AND 2450605  
    GROUP BY 
        ws_item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_marital_status = 'M'
    GROUP BY 
        cd_demo_sk, cd_gender
), 
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        cd_gender,
        cd.customer_count
    FROM 
        RankedSales rs
    INNER JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = rs.ws_item_sk 
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    cd_gender,
    customer_count
FROM 
    TopItems ti
ORDER BY 
    ti.total_sales DESC, 
    cd_gender;
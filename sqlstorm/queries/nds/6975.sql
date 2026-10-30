
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        i.i_item_desc,
        sd.total_sold_quantity,
        sd.total_sales,
        sd.total_discount,
        RANK() OVER (ORDER BY sd.total_sold_quantity DESC) AS sales_rank
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.total_sold_quantity > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
)
SELECT 
    tsi.ws_item_sk,
    tsi.i_item_desc,
    tsi.total_sold_quantity,
    tsi.total_sales,
    tsi.total_discount,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM 
    TopSellingItems tsi
JOIN 
    CustomerDemographics cd ON tsi.ws_item_sk IN (
        SELECT 
            ws_item_sk
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk
        HAVING 
            COUNT(DISTINCT ws_bill_customer_sk) > 50
    )
ORDER BY 
    tsi.total_sales DESC
LIMIT 10;

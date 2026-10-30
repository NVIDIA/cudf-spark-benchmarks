
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
), TopItems AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.ws_item_sk,
        r.total_sales,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 5
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        t.ws_item_sk,
        t.i_item_desc,
        t.i_brand,
        t.total_sales
    FROM 
        TopItems t
    JOIN 
        CustomerDemographics cd ON cd.c_customer_sk = t.ws_bill_customer_sk
)

SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_education_status,
    COUNT(fr.ws_item_sk) AS item_count,
    SUM(fr.total_sales) AS total_spent
FROM 
    FinalReport fr
GROUP BY 
    fr.cd_gender, fr.cd_marital_status, fr.cd_education_status
ORDER BY 
    total_spent DESC;

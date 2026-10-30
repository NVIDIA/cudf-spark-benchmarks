
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.ws_net_profit) AS total_profit
    FROM 
        customer_demographics cd
    JOIN 
        web_sales cs ON cd.cd_demo_sk = cs.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) as sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_web_sales,
    rc.total_catalog_sales,
    rc.total_store_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_profit,
    CASE 
        WHEN rc.total_web_sales > 0 AND cd.cd_gender = 'M' THEN 'High Value Male Web Shopper'
        WHEN rc.total_web_sales > 0 AND cd.cd_gender = 'F' THEN 'High Value Female Web Shopper'
        ELSE 'Other'
    END AS customer_segment
FROM 
    RankedCustomers rc
JOIN 
    CustomerDemographics cd ON rc.sales_rank <= 10 AND rc.c_customer_sk = cd.cd_demo_sk
WHERE 
    (rc.total_web_sales > 1000 OR rc.total_catalog_sales > 1000 OR rc.total_store_sales > 1000)
ORDER BY 
    rc.sales_rank;

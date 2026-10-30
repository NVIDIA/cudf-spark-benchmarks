
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_store_sales,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_transactions
    FROM 
        customer c 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    INNER JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.total_store_transactions,
        cs.total_web_transactions,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
),
FinalSummary AS (
    SELECT 
        *,
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store Dominant' 
            WHEN total_web_sales > total_store_sales THEN 'Web Dominant'
            ELSE 'Equal Sales'
        END AS Sales_Dominance
    FROM 
        SalesSummary
)
SELECT 
    Sales_Dominance,
    COUNT(*) AS Customer_Count,
    AVG(total_store_sales) AS Avg_Store_Sales,
    AVG(total_web_sales) AS Avg_Web_Sales,
    AVG(cd_purchase_estimate) AS Avg_Purchase_Estimate
FROM 
    FinalSummary
GROUP BY 
    Sales_Dominance
ORDER BY 
    Customer_Count DESC;

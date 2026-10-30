
WITH Customer_Statistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(CASE WHEN ws_sold_date_sk IS NOT NULL THEN ws_quantity ELSE 0 END) AS Total_Web_Sales,
        SUM(CASE WHEN cs_sold_date_sk IS NOT NULL THEN cs_quantity ELSE 0 END) AS Total_Catalog_Sales,
        SUM(CASE WHEN ss_sold_date_sk IS NOT NULL THEN ss_quantity ELSE 0 END) AS Total_Store_Sales,
        COALESCE(SUM(ws_quantity), 0) + COALESCE(SUM(cs_quantity), 0) + COALESCE(SUM(ss_quantity), 0) AS Total_Sales,
        COUNT(DISTINCT CASE WHEN ws_web_page_sk IS NOT NULL THEN ws_order_number END) AS Web_Orders_Count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
Ranked_Customers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY Total_Sales DESC) AS Sales_Rank
    FROM 
        Customer_Statistics
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.Total_Sales,
    rc.Web_Orders_Count,
    CASE 
        WHEN rc.Total_Sales > 500 THEN 'High Value'
        WHEN rc.Total_Sales BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Value_Category
FROM 
    Ranked_Customers rc
WHERE 
    rc.Sales_Rank <= 10
    AND rc.cd_gender IS NOT NULL
ORDER BY 
    rc.cd_gender, rc.Total_Sales DESC;


WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_paid DESC) AS rnk
    FROM 
        catalog_sales cs
    JOIN 
        customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
)

SELECT 
    COUNT(*) AS Total_Sales,
    AVG(cs_sales_price) AS Average_Sale_Price,
    SUM(cs_net_paid) AS Total_Net_Paid,
    cd_gender,
    cd_marital_status
FROM 
    RankedSales rs
WHERE 
    rs.rnk <= 10
GROUP BY 
    rs.cd_gender, rs.cd_marital_status
ORDER BY 
    Total_Net_Paid DESC;

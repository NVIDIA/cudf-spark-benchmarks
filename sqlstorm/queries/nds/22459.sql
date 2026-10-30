
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_list_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ext_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
), 
TotalSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_ext_sales_price) AS total_sales,
        COUNT(rs.ws_item_sk) AS items_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1 
    GROUP BY 
        rs.ws_order_number
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000 AND (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NOT NULL)
)
SELECT 
    cs.ws_order_number,
    cs.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cs.total_sales >= 1000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category,
    COUNT(DISTINCT cd.cd_credit_rating) FILTER (WHERE cd.cd_credit_rating IS NOT NULL) AS distinct_credit_ratings
FROM 
    TotalSales cs
LEFT JOIN 
    (SELECT c.c_customer_sk, ws.ws_order_number FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk) cust_sales ON cs.ws_order_number = cust_sales.ws_order_number
LEFT JOIN 
    CustomerDemographics cd ON cust_sales.c_customer_sk = cd.c_customer_sk
GROUP BY 
    cs.ws_order_number, cs.total_sales, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(cs.total_sales) IS NOT NULL AND 
    (COUNT(DISTINCT cd.cd_gender) > 1 OR COUNT(*) <= 10)
ORDER BY 
    cs.total_sales DESC
LIMIT 20;

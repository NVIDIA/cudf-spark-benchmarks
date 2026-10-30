
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS sales_count,
        RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2451201 AND 2451203 
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk, 
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        rs.total_sales, 
        rs.sales_count
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerData AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ti.i_item_desc,
    ti.i_brand,
    ti.i_category,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
    SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
FROM 
    TopItems ti
JOIN 
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
JOIN 
    CustomerData cd ON cd.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ti.i_item_desc, 
    ti.i_brand, 
    ti.i_category
ORDER BY 
    total_purchase_estimate DESC;

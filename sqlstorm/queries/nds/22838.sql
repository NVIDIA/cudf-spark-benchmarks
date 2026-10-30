
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales,
        CONCAT('Item ', ws.ws_item_sk, ' sold on ', d.d_date) AS sale_info
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
),
SalesTax AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * 0.05) AS total_tax,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        rs.ws_item_sk,
        rs.sale_info,
        COALESCE(st.total_tax, 0) AS sales_tax,
        rb.total_sales,
        cd.cd_gender,
        cd.purchase_estimate,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        RANK() OVER (ORDER BY rb.total_sales DESC) AS sales_rank
    FROM 
        RankedSales rs
    JOIN 
        SalesTax st ON rs.ws_item_sk = st.ws_item_sk
    JOIN 
        (SELECT ws_item_sk, MAX(total_sales) AS total_sales 
         FROM RankedSales 
         GROUP BY ws_item_sk) rb ON rs.ws_item_sk = rb.ws_item_sk
    LEFT JOIN 
        CustomerData cd ON cd.c_customer_id = rs.sale_info 
)
SELECT 
    fs.ws_item_sk,
    fs.sale_info,
    fs.sales_tax,
    fs.total_sales,
    fs.cd_gender,
    fs.marital_status,
    fs.purchase_estimate
FROM 
    FinalReport fs
WHERE 
    fs.sales_rank <= 10 
    AND fs.marital_status IS NOT NULL
ORDER BY 
    fs.total_sales DESC;

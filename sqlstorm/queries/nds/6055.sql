
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 100
    GROUP BY 
        ws_bill_customer_sk, 
        ws_ship_customer_sk
), CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), RankedSales AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.ws_ship_customer_sk,
        sd.total_sales,
        sd.order_count,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_bill_customer_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    r.ws_bill_customer_sk,
    r.ws_ship_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    r.total_sales,
    r.order_count
FROM 
    RankedSales r
JOIN 
    CustomerData c ON r.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_sales DESC;

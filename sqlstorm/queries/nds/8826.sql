
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_coupon_amt) AS total_coupons
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_sold_date_sk,
        ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sd.total_sales) AS total_customer_sales,
        SUM(sd.total_quantity) AS total_customer_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_item_sk
    GROUP BY 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_customer_sales DESC) AS sales_rank
    FROM 
        CustomerData
)
SELECT 
    r.c_customer_sk,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status,
    r.total_customer_sales,
    r.total_customer_quantity,
    r.sales_rank
FROM 
    RankedCustomers r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.cd_gender, r.total_customer_sales DESC;


WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        d.d_year,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, c.c_birth_year, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, w.w_warehouse_name
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    total_quantity,
    total_sales,
    total_tax,
    d_year,
    c_birth_year,
    cd_gender,
    cd_marital_status,
    hd_income_band_sk,
    w_warehouse_name
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, total_sales DESC;

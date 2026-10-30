
WITH CustomerPurchaseData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(d.d_date) AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2023
        AND ws.ws_net_paid > 100
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerPurchaseData
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.total_sales,
    c.total_orders,
    c.last_purchase_date,
    c.cd_gender,
    c.cd_marital_status,
    c.ib_income_band_sk
FROM 
    RankedCustomers c
WHERE 
    c.sales_rank <= 10
ORDER BY 
    c.cd_gender, c.total_sales DESC
LIMIT 50;

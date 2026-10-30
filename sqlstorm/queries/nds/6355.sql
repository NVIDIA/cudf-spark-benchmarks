
WITH SaleData AS (
    SELECT 
        s.ss_store_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_ext_sales_price) AS total_revenue,
        AVG(s.ss_sales_price) AS average_sales_price,
        SUM(s.ss_ext_discount_amt) AS total_discount,
        d.d_year AS sales_year
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        s.ss_store_sk, d.d_year
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_ext_discount_amt) AS total_web_discount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
WarehouseData AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    sd.ss_store_sk,
    sd.total_sales,
    sd.total_revenue,
    sd.average_sales_price,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_web_sales,
    cd.total_web_discount,
    wd.total_items,
    wd.total_quantity
FROM 
    SaleData sd
JOIN 
    CustomerData cd ON cd.c_customer_sk IN (
        SELECT DISTINCT ws.ws_bill_customer_sk
        FROM web_sales ws WHERE ws.ws_ship_mode_sk IN (
            SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type = 'STANDARD'
        )
    )
JOIN 
    WarehouseData wd ON wd.w_warehouse_sk IN (
        SELECT DISTINCT s.s_store_sk 
        FROM store s WHERE s.s_number_employees > 50
    )
ORDER BY 
    sd.total_revenue DESC;

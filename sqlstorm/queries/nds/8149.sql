
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_id, 
        SUM(ws.ws_net_paid) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
),
DateRange AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        SUM(ws.ws_ext_tax) AS total_sales_tax
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year IN (2022, 2023)
    GROUP BY 
        d.d_year, 
        d.d_month_seq
)
SELECT 
    ss.w_warehouse_id,
    cd.cd_gender,
    cd.cd_marital_status,
    dr.d_year,
    dr.d_month_seq,
    ss.total_sales,
    ss.total_orders,
    cd.total_customers,
    cd.total_profit,
    dr.total_sales_price,
    dr.total_sales_tax
FROM 
    SalesSummary ss
JOIN 
    CustomerDemographics cd ON 1 = 1 
JOIN 
    DateRange dr ON 1 = 1
ORDER BY 
    ss.w_warehouse_id, 
    cd.cd_gender, 
    dr.d_year, 
    dr.d_month_seq;

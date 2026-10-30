
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        w.w_warehouse_id,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        d.d_year,
        d.d_month_seq
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    AND cd.cd_marital_status = 'M'
    AND cs.cs_sales_price > 50
), AggregatedSales AS (
    SELECT 
        w_warehouse_id,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        AVG(cs_quantity) AS avg_quantity_per_order
    FROM SalesData
    GROUP BY w_warehouse_id
)
SELECT 
    asales.w_warehouse_id,
    asales.unique_customers,
    asales.total_sales,
    asales.total_profit,
    asales.avg_quantity_per_order,
    RANK() OVER (ORDER BY asales.total_sales DESC) AS sales_rank
FROM AggregatedSales asales
ORDER BY asales.total_sales DESC
LIMIT 10;

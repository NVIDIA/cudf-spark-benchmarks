
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        sm.sm_carrier,
        w.w_warehouse_name,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_net_loss,
        sr_return_ship_cost
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN 
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
    WHERE 
        d.d_year = 2023
        AND c.c_current_cdemo_sk IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        sd.c_current_cdemo_sk,
        sd.c_first_name,
        sd.c_last_name,
        COUNT(*) AS total_sales,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_revenue,
        SUM(sd.sr_return_quantity) AS total_returned,
        SUM(sd.sr_return_amt) AS total_return_amount,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        SUM(sd.sr_return_amt) AS total_return_value,
        SUM(sd.sr_return_ship_cost) AS total_ship_cost
    FROM 
        SalesData sd
    GROUP BY 
        sd.c_current_cdemo_sk, sd.c_first_name, sd.c_last_name
)
SELECT 
    ag.c_current_cdemo_sk,
    ag.c_first_name,
    ag.c_last_name,
    ag.total_sales,
    ag.total_revenue,
    ag.total_returned,
    ag.total_return_amount,
    ag.avg_sales_price,
    ag.total_return_value,
    ag.total_ship_cost,
    RANK() OVER (ORDER BY ag.total_revenue DESC) AS revenue_rank
FROM 
    AggregatedSales ag
WHERE 
    ag.total_sales > 10
ORDER BY 
    ag.total_revenue DESC;


WITH SalesSummary AS (
    SELECT 
        d.d_year AS Year,
        SUM(ss_net_paid) AS Total_Sales,
        COUNT(DISTINCT ss_ticket_number) AS Total_Transactions,
        AVG(ss_net_paid) AS Avg_Sale_Amount
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 1998 AND 2001
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        d.d_year
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS Total_Transactions,
        SUM(ss.ss_net_paid) AS Total_Sales,
        SUM(ss.ss_ext_discount_amt) AS Total_Discount
    FROM 
        warehouse w
    JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_id
),
Promotions AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS Promo_Orders,
        SUM(ws.ws_net_profit) AS Promo_Profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk < p.p_end_date_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    s.Year,
    ws.w_warehouse_id,
    s.Total_Sales AS Yearly_Total_Sales,
    s.Total_Transactions AS Yearly_Transactions,
    s.Avg_Sale_Amount,
    SUM(ps.Promo_Profit) AS Total_Promotion_Profit
FROM 
    SalesSummary s
JOIN 
    WarehouseStats ws ON s.Year = EXTRACT(YEAR FROM DATE '2002-10-01')
LEFT JOIN 
    Promotions ps ON ps.Promo_Orders > 0
GROUP BY 
    s.Year, ws.w_warehouse_id, s.Total_Sales, s.Total_Transactions, s.Avg_Sale_Amount
ORDER BY 
    s.Year, ws.w_warehouse_id;

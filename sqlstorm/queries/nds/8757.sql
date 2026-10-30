
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, s.s_store_name
),
SeasonalTrends AS (
    SELECT 
        d.d_month_seq, 
        d.d_year,
        AVG(total_sales) AS avg_sales,
        AVG(total_quantity) AS avg_quantity
    FROM 
        SalesSummary ss
    JOIN 
        date_dim d ON ss.d_year = d.d_year
    GROUP BY 
        d.d_month_seq, d.d_year
),
FinalReport AS (
    SELECT 
        st.d_month_seq, 
        st.d_year,
        st.avg_sales,
        st.avg_quantity,
        CASE 
            WHEN st.avg_sales > 10000 THEN 'High'
            WHEN st.avg_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        SeasonalTrends st
)
SELECT 
    fr.d_year, 
    fr.d_month_seq, 
    fr.avg_sales, 
    fr.avg_quantity, 
    fr.sales_category
FROM 
    FinalReport fr
ORDER BY 
    fr.d_year, fr.d_month_seq;

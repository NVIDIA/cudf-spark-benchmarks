WITH  SalesTrend AS (
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS total_profit, 
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
), 
TopStores AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        SUM(ss_net_profit) AS store_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s_store_sk, s_store_name
), 
StorePerformance AS (
    SELECT 
        st.s_store_name, 
        st.store_profit, 
        CASE 
            WHEN st.store_profit > (SELECT AVG(store_profit) FROM TopStores) THEN 'Above Average'
            ELSE 'Below Average'
        END AS performance_category
    FROM 
        TopStores st
), 
CustomerReturns AS (
    SELECT 
        c.c_customer_id, 
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)

SELECT 
    cs.c_customer_id,
    cs.total_return_amount,
    sp.s_store_name,
    sp.performance_category,
    st.d_year,
    st.total_profit
FROM 
    CustomerReturns cs
LEFT JOIN 
    StorePerformance sp ON cs.total_return_amount > 500  
JOIN 
    SalesTrend st ON st.profit_rank <= 10  
WHERE 
    cs.total_return_amount IS NOT NULL
ORDER BY 
    cs.total_return_amount DESC, sp.performance_category DESC;
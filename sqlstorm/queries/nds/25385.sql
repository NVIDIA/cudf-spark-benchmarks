
WITH CustomerLocation AS (
    SELECT 
        ca_city, 
        ca_state,
        COUNT(DISTINCT c_customer_id) AS total_customers
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_city, 
        ca_state
), 
PromotionalImpact AS (
    SELECT 
        p.p_promo_id,
        SUM(CASE 
            WHEN ws_sold_date_sk IS NOT NULL THEN ws_quantity 
            ELSE 0 
        END) AS total_sold,
        SUM(ws_net_profit) AS total_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
), 
SalesTrends AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS annual_sales,
        SUM(ws_ext_discount_amt) AS total_discounts
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
), 
WarehouseInventory AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cl.ca_city,
    cl.ca_state,
    cl.total_customers,
    pi.p_promo_id,
    pi.total_sold,
    pi.total_profit,
    st.d_year,
    st.annual_sales,
    st.total_discounts,
    wi.w_warehouse_id,
    wi.total_inventory
FROM 
    CustomerLocation cl
LEFT JOIN 
    PromotionalImpact pi ON cl.total_customers > 1000
LEFT JOIN 
    SalesTrends st ON pi.total_sold > 50
LEFT JOIN 
    WarehouseInventory wi ON wi.total_inventory < 100
ORDER BY 
    cl.ca_city, 
    cl.ca_state;

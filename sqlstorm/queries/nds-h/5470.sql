
WITH SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand, p.p_retailprice, s.s_name, s.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_order_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        SUM(l.l_tax) AS total_tax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
Summary AS (
    SELECT 
        sd.p_name,
        sd.p_brand,
        od.o_orderkey,
        od.o_orderdate,
        od.total_order_quantity,
        sd.total_available_quantity,
        sd.total_supply_cost,
        od.net_revenue,
        od.total_tax,
        CASE 
            WHEN od.net_revenue > 100000 THEN 'High Revenue'
            WHEN od.net_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
            ELSE 'Low Revenue'
        END AS revenue_category
    FROM 
        SupplyDetails sd
    JOIN 
        OrderDetails od ON sd.ps_partkey = od.o_orderkey
)
SELECT 
    p_name,
    p_brand,
    COUNT(*) AS order_count,
    SUM(total_order_quantity) AS total_ordered,
    AVG(total_supply_cost) AS avg_supply_cost,
    SUM(net_revenue) AS total_net_revenue,
    SUM(total_tax) AS total_tax_collected,
    revenue_category
FROM 
    Summary
GROUP BY 
    p_name, p_brand, revenue_category
ORDER BY 
    total_net_revenue DESC, order_count DESC
LIMIT 100;

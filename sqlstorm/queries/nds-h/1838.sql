WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        o_orderkey, 
        total_revenue
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 10
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(tp.total_revenue), 0) AS total_order_revenue,
    COALESCE(spd.total_supply_cost, 0) AS total_supply_cost,
    (COALESCE(SUM(tp.total_revenue), 0) - COALESCE(spd.total_supply_cost, 0)) AS profit_margin
FROM 
    part p
LEFT JOIN 
    TopOrders tp ON p.p_partkey = tp.o_orderkey
LEFT JOIN 
    SupplierPartDetails spd ON p.p_partkey = spd.ps_partkey
GROUP BY 
    p.p_name, p.p_brand, spd.total_supply_cost
ORDER BY 
    profit_margin DESC;
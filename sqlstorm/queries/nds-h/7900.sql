WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderDetails AS (
    SELECT 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_custkey
) 
SELECT 
    n.n_name AS nation_name,
    SUM(sp.total_supply_cost) AS nation_total_supply_cost,
    SUM(od.total_revenue) AS nation_total_revenue,
    COUNT(DISTINCT od.o_custkey) AS unique_customers,
    SUM(sp.part_count) AS total_parts_supplied
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierParts sp ON n.n_nationkey = sp.s_suppkey
LEFT JOIN 
    OrderDetails od ON n.n_nationkey = od.o_custkey
WHERE 
    r.r_name = 'EUROPE'
GROUP BY 
    n.n_name
ORDER BY 
    nation_total_revenue DESC
LIMIT 10;

WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority, 
        COUNT(l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority
    HAVING 
        COUNT(l.l_linenumber) > 0
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 0
), RegionStats AS (
    SELECT 
        r.r_name, 
        AVG(o.o_totalprice) AS avg_order_value, 
        SUM(CASE WHEN o.o_orderpriority = 'HIGH' THEN 1 ELSE 0 END) AS high_priority_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    R.r_name, 
    R.avg_order_value, 
    R.high_priority_orders, 
    S.s_name AS supplier_name, 
    S.supplied_parts,
    RO.line_count
FROM 
    RegionStats R
LEFT JOIN 
    FilteredSuppliers S ON R.high_priority_orders > 0
LEFT JOIN 
    RankedOrders RO ON RO.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= DATE '1997-01-01')
ORDER BY 
    R.avg_order_value DESC, 
    S.supplied_parts DESC, 
    RO.line_count DESC
LIMIT 100;

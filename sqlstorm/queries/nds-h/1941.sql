WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    JOIN 
        customer c ON c.c_nationkey = s.s_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, c.c_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    n.n_name AS nation_name,
    p.p_name AS product_name,
    COUNT(DISTINCT h.o_orderkey) AS total_orders,
    COALESCE(SUM(r.total_supply_cost), 0) AS total_supplier_cost,
    AVG(CASE WHEN r.supplier_rank <= 5 THEN r.total_supply_cost END) AS avg_top_suppliers_cost
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    HighValueOrders h ON h.o_custkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers r ON s.s_suppkey = r.s_suppkey
WHERE 
    p.p_size > 10 
    AND n.n_name LIKE 'U%' 
GROUP BY 
    n.n_name, p.p_name
ORDER BY 
    total_orders DESC, total_supplier_cost DESC;

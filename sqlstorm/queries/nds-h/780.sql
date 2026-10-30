WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
NationSuppliers AS (
    SELECT 
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.r_name,
    COALESCE(ns.supplier_count, 0) AS supplier_count,
    COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
    AVG(r.total_supply_cost) AS avg_supply_cost
FROM 
    region n
LEFT JOIN 
    NationSuppliers ns ON n.r_name = ns.n_name
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey IN (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_orderstatus = 'O'
    )
LEFT JOIN 
    RankedSuppliers r ON ns.supplier_count > 0
WHERE 
    r.supplier_rank = 1 OR r.supplier_rank IS NULL
GROUP BY 
    n.r_name, ns.supplier_count
ORDER BY 
    n.r_name;

WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
), TotalLineItem AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
), QualifiedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        COALESCE(t.total_revenue, 0) AS revenue
    FROM 
        orders o
    LEFT JOIN 
        TotalLineItem t ON o.o_orderkey = t.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    n.n_name, 
    COUNT(DISTINCT q.o_orderkey) AS total_orders,
    AVG(q.o_totalprice) AS avg_order_value,
    SUM(r.total_supply_cost) AS total_supplier_cost
FROM 
    QualifiedOrders q
JOIN 
    customer c ON q.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    RankedSuppliers r ON q.o_orderkey = r.s_suppkey
GROUP BY 
    n.n_name
HAVING 
    SUM(r.total_supply_cost) IS NOT NULL
ORDER BY 
    total_orders DESC;
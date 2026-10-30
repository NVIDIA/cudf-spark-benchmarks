
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        o.o_orderkey, 
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
), 
NationRegions AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    co.c_name AS customer_name, 
    ns.n_name AS nation_name, 
    rs.s_name AS supplier_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    CustomerOrders co
JOIN 
    lineitem l ON co.o_orderkey = l.l_orderkey
JOIN 
    RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
JOIN 
    NationRegions ns ON co.c_nationkey = ns.n_nationkey
GROUP BY 
    co.c_name, ns.n_name, rs.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    ns.n_name, revenue DESC;

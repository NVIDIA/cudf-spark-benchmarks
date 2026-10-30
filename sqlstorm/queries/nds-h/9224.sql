WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
TopSuppliers AS (
    SELECT 
        s.*, 
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.total_supply_cost DESC) AS rank
    FROM 
        RankedSuppliers s
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region, 
    n.n_name AS nation, 
    ts.s_name AS supplier_name, 
    COUNT(DISTINCT co.o_orderkey) AS order_count, 
    SUM(co.revenue) AS total_revenue
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    CustomerOrders co ON ts.s_suppkey = co.c_custkey
WHERE 
    ts.rank <= 5
GROUP BY 
    r.r_name, n.n_name, ts.s_name
ORDER BY 
    region, nation, total_revenue DESC;

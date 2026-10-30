WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS region_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.total_cost
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.s_suppkey
    WHERE 
        rs.region_rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.r_name,
    ts.s_name,
    COALESCE(SUM(co.total_revenue), 0) AS total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    CustomerOrders co ON ts.s_name = co.c_name
GROUP BY 
    ts.r_name, ts.s_name
ORDER BY 
    ts.r_name, total_revenue DESC;

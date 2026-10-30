
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
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name,
        n.n_name AS nation_name,
        rs.total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY rs.total_cost DESC) AS supplier_rank
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
ProcessedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_order_value,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, o.o_orderdate
)
SELECT 
    ts.s_name,
    ts.nation_name,
    COUNT(DISTINCT po.o_orderkey) AS order_count,
    SUM(po.total_order_value) AS total_value,
    MAX(po.o_orderdate) AS last_order_date
FROM 
    TopSuppliers ts
JOIN 
    ProcessedOrders po ON ts.s_suppkey = po.c_custkey
WHERE 
    ts.supplier_rank <= 10
GROUP BY 
    ts.s_name, ts.nation_name
ORDER BY 
    total_value DESC
LIMIT 10;

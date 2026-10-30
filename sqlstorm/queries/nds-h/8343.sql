
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        rs.nation_name, 
        rs.s_name, 
        rs.total_avail_qty, 
        rs.total_supply_cost,
        rs.s_suppkey
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    ts.region_name, 
    ts.nation_name, 
    SUM(LI.l_extendedprice * (1 - LI.l_discount)) AS total_revenue
FROM 
    lineitem LI
JOIN 
    orders O ON LI.l_orderkey = O.o_orderkey
JOIN 
    TopSuppliers ts ON LI.l_suppkey = ts.s_suppkey
WHERE 
    O.o_orderstatus = 'F'
GROUP BY 
    ts.region_name, ts.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 10;

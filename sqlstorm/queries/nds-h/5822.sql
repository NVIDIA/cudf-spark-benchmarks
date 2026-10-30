WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    ts.region_name,
    ts.s_name,
    ts.total_supply_cost,
    COUNT(o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(c.c_acctbal) AS avg_customer_balance
FROM 
    TopSuppliers ts
LEFT JOIN 
    orders o ON ts.s_name = o.o_clerk
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    ts.region_name, ts.s_name, ts.total_supply_cost
ORDER BY 
    ts.region_name, total_supply_cost DESC;

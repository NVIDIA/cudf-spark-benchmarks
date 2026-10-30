WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
PurchasingCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 10
)
SELECT 
    r.r_name AS region_name, 
    ts.n_name AS nation_name, 
    rs.s_name AS supplier_name, 
    pc.c_name AS customer_name, 
    pc.total_spent, 
    rs.total_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation ts ON rs.s_nationkey = ts.n_nationkey
JOIN 
    PurchasingCustomers pc ON rs.s_nationkey = pc.c_nationkey
JOIN 
    region r ON ts.n_regionkey = r.r_regionkey
WHERE 
    rs.rank <= 5 AND 
    pc.total_spent > 1000
ORDER BY 
    r.r_name, ts.n_name, pc.total_spent DESC;
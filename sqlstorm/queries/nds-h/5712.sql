
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, n.n_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    ss.s_name,
    ss.total_supply_cost,
    co.order_count,
    co.total_spent
FROM 
    RankedSuppliers ss
JOIN 
    nation n ON ss.n_nationkey = n.n_nationkey
JOIN 
    CustomerOrders co ON co.c_custkey = ss.s_suppkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ss.rank <= 5
ORDER BY 
    r.r_name, ss.total_supply_cost DESC;

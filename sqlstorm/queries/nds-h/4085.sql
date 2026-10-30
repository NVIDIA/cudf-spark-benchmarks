
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
), 
NationCustomer AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(co.total_spent) AS total_revenue
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ns.n_name,
    COALESCE(nc.total_revenue, 0) AS total_revenue,
    COALESCE(sd.total_supply_cost, 0) AS total_supply_cost
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    NationCustomer nc ON ns.n_nationkey = nc.n_nationkey
LEFT JOIN 
    SupplierDetails sd ON ns.n_nationkey = sd.s_nationkey AND sd.rn = 1
WHERE 
    (COALESCE(nc.total_revenue, 0) > 10000 OR COALESCE(sd.total_supply_cost, 0) > 5000)
ORDER BY 
    r.r_name, ns.n_name;

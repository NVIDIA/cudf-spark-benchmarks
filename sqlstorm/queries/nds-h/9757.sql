WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationRegionData AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nrd.region_name,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    rs.s_name AS top_supplier,
    rs.total_cost
FROM 
    CustomerOrderSummary cs
JOIN 
    NationRegionData nrd ON cs.c_custkey = nrd.n_nationkey
JOIN 
    (SELECT * FROM RankedSuppliers WHERE rank = 1) rs ON cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC, rs.total_cost DESC
LIMIT 10;

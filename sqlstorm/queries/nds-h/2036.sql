
WITH CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopRegions AS (
    SELECT 
        n.n_name AS region_name,
        SUM(cs.total_spent) AS total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_sales DESC
    LIMIT 5
)
SELECT 
    tr.region_name,
    SUM(sp.parts_available) AS total_parts,
    AVG(sp.avg_supply_cost) AS avg_supply_cost_per_part
FROM 
    TopRegions tr
LEFT JOIN 
    SupplierParts sp ON sp.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
    )
GROUP BY 
    tr.region_name
ORDER BY 
    total_parts DESC;

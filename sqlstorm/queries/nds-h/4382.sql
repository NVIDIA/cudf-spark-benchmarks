WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
),
SupplierRegionComparison AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    crd.c_custkey,
    crd.c_name,
    crd.total_order_value,
    sr.supplier_count,
    sr.avg_supply_cost,
    COALESCE(rs.rank, 0) AS supplier_rank,
    CASE 
        WHEN crd.total_order_value < (SELECT AVG(total_order_value) FROM CustomerOrderDetails) THEN 'Below Average'
        ELSE 'Above Average'
    END AS order_value_comparison
FROM 
    CustomerOrderDetails crd
LEFT JOIN 
    SupplierRegionComparison sr ON crd.o_orderkey = sr.supplier_count
LEFT JOIN 
    RankedSuppliers rs ON crd.c_custkey = rs.s_suppkey
WHERE 
    crd.order_count > 5
ORDER BY 
    crd.total_order_value DESC;
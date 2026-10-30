WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
SupplierRegions AS (
    SELECT 
        s.s_suppkey,
        r.r_regionkey,
        r.r_name
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    psd.total_available,
    psd.avg_supply_cost,
    sr.r_name AS supplier_region,
    CASE 
        WHEN os.total_revenue > 10000 THEN 'High Value'
        WHEN os.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS revenue_category,
    ROW_NUMBER() OVER (PARTITION BY sr.r_name ORDER BY os.total_revenue DESC) AS revenue_rank
FROM 
    OrderSummary os
JOIN 
    lineitem l ON os.o_orderkey = l.l_orderkey
JOIN 
    PartSupplierDetails psd ON l.l_partkey = psd.ps_partkey
LEFT JOIN 
    SupplierRegions sr ON l.l_suppkey = sr.s_suppkey
WHERE 
    os.unique_suppliers > 1
ORDER BY 
    os.total_revenue DESC, 
    sr.r_name;
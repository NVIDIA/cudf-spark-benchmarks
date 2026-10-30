
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_by_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
SalesData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey
),
CustomerRegions AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.supplier_count,
    rp.total_availqty,
    COALESCE(td.total_sales, 0) AS total_sales,
    CASE WHEN cr.customer_count > 100 THEN 'High' ELSE 'Low' END AS customer_density,
    ts.s_name AS top_supplier
FROM 
    RankedParts rp
LEFT JOIN 
    SalesData td ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM TopSuppliers s WHERE s.supplier_rank = 1))
LEFT JOIN 
    CustomerRegions cr ON rp.p_brand = cr.region_name
LEFT JOIN 
    TopSuppliers ts ON rp.supplier_count = ts.supplier_rank
WHERE 
    rp.rank_by_cost <= 10 AND (rp.total_availqty IS NULL OR rp.total_availqty > 500)
ORDER BY 
    rp.p_brand, rp.p_name;

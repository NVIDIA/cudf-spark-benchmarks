
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey
), 
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS region_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)

SELECT 
    cr.r_name AS region_name,
    SUM(os.total_revenue) AS total_sales,
    COUNT(DISTINCT cr.c_custkey) AS customer_count,
    COALESCE(RS.s_name, 'No Supplier') AS top_supplier
FROM 
    OrderSummary os
JOIN 
    orders o ON os.o_orderkey = o.o_orderkey
JOIN 
    CustomerRegions cr ON o.o_custkey = cr.c_custkey
LEFT JOIN 
    RankedSuppliers RS ON RS.rn = 1 AND RS.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10) LIMIT 1)
WHERE 
    cr.region_rank = 1
GROUP BY 
    cr.r_name, RS.s_name
HAVING 
    SUM(os.total_revenue) > 10000
ORDER BY 
    total_sales DESC;

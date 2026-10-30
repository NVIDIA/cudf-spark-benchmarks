WITH SupplierCostRanked AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM 
        partsupp ps
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
        AND n.n_name LIKE 'S%'
),
OrderSummaries AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice) AS total_sales_value,
    MAX(sc.ps_supplycost) AS max_supplier_cost,
    ARRAY_AGG(DISTINCT fs.nation_name) AS supplier_nations
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierCostRanked sc ON p.p_partkey = sc.ps_partkey AND sc.cost_rank = 1
LEFT JOIN 
    FilteredSuppliers fs ON sc.ps_suppkey = fs.s_suppkey
WHERE 
    p.p_retailprice < 1000.00 
    AND (p.p_size BETWEEN 5 AND 10 OR p.p_brand LIKE 'Brand%')
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 0 
    OR MAX(sc.ps_supplycost) IS NOT NULL
ORDER BY 
    total_sales_value DESC;

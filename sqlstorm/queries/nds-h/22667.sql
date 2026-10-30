
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        CASE
            WHEN p.p_size < 1 THEN 'Small'
            WHEN p.p_size BETWEEN 1 AND 5 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND p.p_size IS NOT NULL
), SupplierPartAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_retailprice,
    fp.size_category,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(sp.total_avail_qty) AS total_availability,
    AVG(sp.total_supply_cost) AS avg_supply_cost,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END) AS max_return_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    FilteredParts fp
LEFT JOIN 
    SupplierPartAvailability sp ON fp.p_partkey = sp.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON sp.ps_suppkey = s.s_suppkey AND s.rnk = 1
LEFT JOIN 
    lineitem l ON fp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    fp.p_retailprice > 20.00 AND 
    (fp.size_category = 'Large' OR fp.size_category IS NULL)
GROUP BY 
    fp.p_partkey, fp.p_name, fp.p_retailprice, fp.size_category, s.s_name
HAVING 
    SUM(sp.total_avail_qty) > 0 AND 
    AVG(sp.total_supply_cost) < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
ORDER BY 
    fp.p_retailprice DESC,
    order_count DESC;

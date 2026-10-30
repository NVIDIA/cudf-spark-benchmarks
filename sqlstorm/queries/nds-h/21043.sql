WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank_order
    FROM 
        part p
    INNER JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 100)
    UNION
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank_order
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty IS NULL OR p.p_size >= 100
), FilteredSupplier AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS return_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
    HAVING 
        SUM(CASE WHEN l.l_discount > 0 THEN 1 ELSE 0 END) > 5
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    AVG(f.return_value) AS avg_return_value,
    SUM(CASE WHEN f.order_count > 10 THEN 1 ELSE 0 END) AS high_order_suppliers
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    FilteredSupplier f ON f.s_suppkey IN (SELECT s_nationkey FROM supplier WHERE s_name LIKE 'Supplier%')
WHERE 
    r.r_name LIKE 'E%' OR r.r_name IS NULL 
GROUP BY 
    r.r_name;

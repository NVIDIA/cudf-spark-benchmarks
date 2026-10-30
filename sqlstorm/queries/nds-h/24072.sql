WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity * (1 - l.l_discount) AS net_price,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        lineitem l
)
SELECT 
    p.p_name,
    SUM(f.net_price) AS total_net_price,
    COUNT(DISTINCT f.l_orderkey) AS total_orders,
    MAX(s.rank) AS highest_rank_supplier,
    r.r_name
FROM 
    part p
LEFT JOIN 
    FilteredLineItems f ON p.p_partkey = f.l_partkey
LEFT JOIN 
    RankedSuppliers s ON f.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 20) 
    AND COALESCE(s.rank, 0) < 3
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT f.l_orderkey) > 5
ORDER BY 
    total_net_price DESC, r.r_name ASC;

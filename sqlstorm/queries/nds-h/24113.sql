WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2
            WHERE o2.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
        )
),
TopNationSuppliers AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        SUM(s.s_acctbal) > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
        )
),
PartSelection AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size BETWEEN 1 AND 50 THEN 'Small'
            WHEN p.p_size BETWEEN 51 AND 100 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice < (
            SELECT AVG(p2.p_retailprice)
            FROM part p2
        )
)
SELECT 
    p.p_name,
    ps.ps_supplycost,
    COUNT(l.l_orderkey) AS order_count,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT ao.o_orderkey) AS total_orders,
    n.n_name AS supplier_nation,
    r.r_name AS region_name
FROM 
    PartSelection p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey 
LEFT JOIN 
    RankedOrders ao ON l.l_orderkey = ao.o_orderkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.size_category = 'Medium' 
    AND s.s_acctbal IS NOT NULL
GROUP BY 
    p.p_name, ps.ps_supplycost, n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT ao.o_orderkey) > 0
ORDER BY 
    average_discount DESC, total_orders DESC;

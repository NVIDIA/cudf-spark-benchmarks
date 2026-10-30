
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
NationRegion AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_regionkey, 
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nr.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(sd.total_supplycost) AS avg_supplycost,
    MAX(sd.total_available) AS max_available,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returns
FROM 
    SupplierDetails sd
LEFT JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    NationRegion nr ON c.c_nationkey = nr.n_nationkey
WHERE 
    sd.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierDetails)
    AND nr.r_name IS NOT NULL
GROUP BY 
    nr.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    customer_count DESC;

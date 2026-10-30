WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
AveragePrice AS (
    SELECT 
        p.p_partkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        p.p_partkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    r.r_name,
    p.p_name,
    COALESCE(s.s_name, 'N/A') AS supplier_name,
    tp.total_spent,
    ap.avg_price,
    SUM(CASE 
          WHEN l.l_returnflag = 'R' THEN l.l_quantity 
          ELSE 0 
        END) AS returned_quantity,
    COUNT(DISTINCT l.l_orderkey) AS order_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    AveragePrice ap ON p.p_partkey = ap.p_partkey
LEFT JOIN 
    TopCustomers tp ON s.s_suppkey = tp.c_custkey
WHERE 
    r.r_name LIKE 'E%' 
GROUP BY 
    r.r_name, p.p_name, s.s_name, tp.total_spent, ap.avg_price
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    r.r_name, p.p_name;
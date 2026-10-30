
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighBalanceCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    n.n_name,
    p.p_name,
    ps.ps_availqty,
    COALESCE(SUM(l.l_quantity * (1 - l.l_discount)), 0) AS total_sales,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count,
    COUNT(l.l_orderkey) AS total_orders,
    CASE 
        WHEN COUNT(l.l_orderkey) > 0 THEN SUM(l.l_extendedprice * (1 - l.l_discount))
        ELSE 0
    END AS revenue
FROM 
    lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank <= 3
    LEFT JOIN HighBalanceCustomers hbc ON o.o_custkey = hbc.c_custkey
WHERE 
    p.p_retailprice BETWEEN 10 AND 100
    AND n.n_name IS NOT NULL
    AND l.l_shipdate >= DATE '1995-01-01' 
    AND (l.l_comment LIKE '%urgent%' OR l.l_comment LIKE '%immediate%')
GROUP BY 
    n.n_name, p.p_name, ps.ps_availqty
HAVING 
    COUNT(DISTINCT hbc.c_custkey) > 0
ORDER BY 
    total_sales DESC, p.p_name ASC
LIMIT 50;

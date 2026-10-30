
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
)
SELECT 
    p.p_name,
    r.r_name,
    n.n_name,
    COALESCE(SUM(lp.l_extendedprice * (1 - lp.l_discount)), 0) AS total_sales,
    (SELECT COUNT(*) FROM CustomerSpending cs WHERE cs.total_spent > 5000) AS high_spending_customers,
    si.total_available
FROM 
    part p
LEFT JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
JOIN 
    supplier s ON lp.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierPartInfo si ON p.p_partkey = si.ps_partkey
WHERE 
    p.p_retailprice > 50 
    AND (p.p_comment LIKE '%special%' OR p.p_comment IS NULL)
GROUP BY 
    p.p_name, r.r_name, n.n_name, si.total_available
HAVING 
    COALESCE(SUM(lp.l_extendedprice * (1 - lp.l_discount)), 0) > 2000 
ORDER BY 
    total_sales DESC, p.p_name;

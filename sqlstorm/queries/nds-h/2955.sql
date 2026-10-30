WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
LineitemAnalysis AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' AND 
        l.l_shipdate >= '1996-01-01' AND 
        l.l_shipdate <= '1996-12-31'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_name,
    pa.total_revenue AS part_revenue,
    cs.total_spent AS customer_spending,
    rs.s_name AS supplier_name,
    rs.s_acctbal AS supplier_balance
FROM 
    part p
LEFT JOIN 
    LineitemAnalysis pa ON p.p_partkey = pa.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank <= 3
JOIN 
    CustomerOrderSummary cs ON cs.order_count > 0
WHERE 
    p.p_retailprice BETWEEN 10 AND 100
    AND (pa.order_count IS NOT NULL OR cs.order_count IS NOT NULL)
ORDER BY 
    part_revenue DESC, 
    customer_spending DESC;
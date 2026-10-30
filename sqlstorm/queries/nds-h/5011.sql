WITH RevenueCTE AS (
    SELECT 
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND 
        o.o_orderdate < DATE '1996-01-01' 
    GROUP BY 
        n.n_name
),
TopNationsCTE AS (
    SELECT 
        nation, 
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueCTE
)
SELECT 
    tn.nation,
    tn.total_revenue,
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_suppkey) AS part_count,
    AVG(s.s_acctbal) AS avg_account_balance
FROM 
    TopNationsCTE tn
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100)
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    tn.revenue_rank <= 5
GROUP BY 
    tn.nation, tn.total_revenue, s.s_name
ORDER BY 
    tn.total_revenue DESC;
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
),
PartRevenue AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_revenue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cd.c_name,
    cd.nation_name,
    COUNT(DISTINCT ro.o_orderkey) AS num_orders,
    COALESCE(SUM(pr.part_revenue), 0) AS total_part_revenue,
    MAX(ro.total_revenue) AS max_order_revenue
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedOrders ro ON cd.c_custkey = ro.o_orderkey
LEFT JOIN 
    PartRevenue pr ON ro.o_orderkey = pr.p_partkey
WHERE 
    cd.avg_acct_balance IS NOT NULL AND 
    cd.nation_name IS NOT NULL
GROUP BY 
    cd.c_name, cd.nation_name
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 5 AND 
    SUM(pr.part_revenue) IS NOT NULL
ORDER BY 
    total_part_revenue DESC, 
    num_orders DESC;